import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';

// Load config
const config = JSON.parse(readFileSync('./config.json', 'utf-8'));

// Initialize Supabase client
const supabase = createClient(config.supabase.url, config.supabase.anonKey);

async function testConnection() {
  console.log('🔌 Testing Supabase connection...\n');

  try {
    // Get the current user
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (userError) {
      console.error('❌ Error getting user:', userError.message);
      console.log('\n💡 Note: You need to be authenticated. The script will try to fetch projects anyway.\n');
    } else if (user) {
      console.log('✅ Authenticated as:', user.email);
      console.log('   User ID:', user.id, '\n');
    }

    // Fetch projects for the current user
    console.log('📂 Fetching your projects...\n');
    
    const { data: projects, error: projectsError } = await supabase
      .from('projects')
      .select(`
        id,
        name,
        invite_code,
        created_at,
        project_members (
          role,
          user_id
        )
      `);

    if (projectsError) {
      console.error('❌ Error fetching projects:', projectsError.message);
      console.log('\n💡 Make sure your RLS policies allow reading projects.');
      return;
    }

    if (!projects || projects.length === 0) {
      console.log('📭 No projects found for your user.');
      return;
    }

    console.log(`✅ Found ${projects.length} project(s):\n`);
    
    projects.forEach((project, index) => {
      console.log(`${index + 1}. ${project.name}`);
      console.log(`   ID: ${project.id}`);
      console.log(`   Invite Code: ${project.invite_code}`);
      console.log(`   Created: ${new Date(project.created_at).toLocaleString()}`);
      console.log(`   Members: ${project.project_members?.length || 0}`);
      console.log('');
    });

  } catch (error) {
    console.error('❌ Unexpected error:', error.message);
  }
}

testConnection();
