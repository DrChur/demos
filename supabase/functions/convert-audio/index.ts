// Supabase Edge Function for WAV to MP3 conversion
// Deploy with: supabase functions deploy convert-audio

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ConversionRequest {
  songId: string;
  projectId: string;
  originalFilePath: string;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get request body
    const { songId, projectId, originalFilePath }: ConversionRequest = await req.json();

    if (!songId || !projectId || !originalFilePath) {
      throw new Error('Missing required parameters');
    }

    console.log(`Converting audio for song ${songId}`);

    // Download the original WAV file from storage
    const { data: fileData, error: downloadError } = await supabase.storage
      .from('audio')
      .download(originalFilePath);

    if (downloadError || !fileData) {
      throw new Error(`Failed to download file: ${downloadError?.message}`);
    }

    console.log(`Downloaded file, size: ${fileData.size} bytes`);

    // NOTE: Actual WAV to MP3 conversion requires FFmpeg
    // Since Deno Deploy doesn't support FFmpeg natively, you have a few options:
    // 
    // 1. Use an external API service (e.g., CloudConvert, Zamzar)
    // 2. Use FFmpeg WASM (performance may vary)
    // 3. Use a dedicated conversion service
    // 4. For MVP: Just copy the file as-is and skip conversion
    //
    // For this implementation, we'll provide a placeholder that logs the requirement
    // and marks the song as "conversion pending" or uses the original file

    // PLACEHOLDER: In production, implement actual conversion here
    // For now, we'll just use the original file as the streaming file
    
    const outputPath = originalFilePath.replace(/\/original\.(wav|WAV)$/, '/stream.mp3');
    
    // For MVP: Copy original file to streaming location
    // In production: Replace this with actual conversion
    const { error: uploadError } = await supabase.storage
      .from('audio')
      .upload(outputPath, fileData, {
        contentType: 'audio/mpeg',
        upsert: true
      });

    if (uploadError) {
      throw new Error(`Failed to upload converted file: ${uploadError.message}`);
    }

    // Get public URL for the converted file
    const { data: { publicUrl } } = supabase.storage
      .from('audio')
      .getPublicUrl(outputPath);

    // Update song record with streaming URL
    const { error: updateError } = await supabase
      .from('songs')
      .update({
        file_url: publicUrl, // Use converted file for streaming
      })
      .eq('id', songId);

    if (updateError) {
      throw new Error(`Failed to update song record: ${updateError.message}`);
    }

    console.log(`Conversion complete for song ${songId}`);

    return new Response(
      JSON.stringify({
        success: true,
        songId,
        streamingUrl: publicUrl,
        message: 'Audio conversion completed (using original file as placeholder)'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    console.error('Conversion error:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});
