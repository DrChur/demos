# Audio Conversion Edge Function

This Supabase Edge Function handles WAV to MP3 conversion for uploaded audio files.

## Current Status

**This is a placeholder implementation.** The function currently copies the original file to the streaming location without actual conversion. This allows the app to work immediately while proper conversion is implemented.

## Deployment

### Prerequisites

1. Install Supabase CLI:
```bash
npm install -g supabase
```

2. Link your project:
```bash
supabase link --project-ref your-project-ref
```

### Deploy

```bash
supabase functions deploy convert-audio
```

### Set Secrets

The function needs access to these environment variables (automatically available):
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for admin access

## Usage

Call the function from your application:

```javascript
const { data, error } = await supabase.functions.invoke('convert-audio', {
  body: {
    songId: 'uuid-of-song',
    projectId: 'uuid-of-project',
    originalFilePath: 'project-id/song-id/original.wav'
  }
});
```

## Production Implementation Options

To implement actual WAV to MP3 conversion, consider these approaches:

### Option 1: External API Service
Use a service like CloudConvert, Zamzar, or similar:
```typescript
// Example with CloudConvert
const cloudConvert = new CloudConvert(apiKey);
const job = await cloudConvert.jobs.create({
  tasks: {
    'import-file': { operation: 'import/url', url: sourceUrl },
    'convert-audio': {
      operation: 'convert',
      input: 'import-file',
      output_format: 'mp3',
      audio_codec: 'mp3',
      audio_bitrate: 192
    },
    'export-file': { operation: 'export/url', input: 'convert-audio' }
  }
});
```

### Option 2: FFmpeg WASM
Use FFmpeg compiled to WebAssembly:
```typescript
import { FFmpeg } from '@ffmpeg/ffmpeg';
const ffmpeg = new FFmpeg();
await ffmpeg.load();
await ffmpeg.writeFile('input.wav', audioData);
await ffmpeg.exec(['-i', 'input.wav', '-b:a', '192k', 'output.mp3']);
const mp3Data = await ffmpeg.readFile('output.mp3');
```

Note: FFmpeg WASM can be resource-intensive on Edge Functions.

### Option 3: Dedicated Conversion Service
Deploy a separate service (e.g., on AWS Lambda, Google Cloud Functions) with native FFmpeg:
```typescript
const response = await fetch('https://your-conversion-service.com/convert', {
  method: 'POST',
  body: JSON.stringify({ fileUrl, format: 'mp3' })
});
```

### Option 4: Pre-conversion on Upload
Convert files client-side before upload using browser libraries:
```typescript
// Use lamejs or similar
import lamejs from 'lamejs';
// Convert WAV to MP3 in browser before upload
```

## Recommendations

For production use:
1. **For MVP**: Use Option 4 (client-side conversion) or skip conversion and accept MP3 only
2. **For scale**: Use Option 1 (External API) for reliability and quality
3. **For control**: Use Option 3 (Dedicated service) with native FFmpeg

The current placeholder allows immediate functionality while you implement the appropriate solution for your needs.
