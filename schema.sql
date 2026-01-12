-- Database schema for songwriting demo app

create extension if not exists pgcrypto;

create or replace function generate_invite_code()
returns text
language plpgsql
as $$
declare
  code text;
begin
  code := substring(encode(gen_random_bytes(8), 'hex') from 1 for 10);
  return code;
end;
$$;

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text not null default generate_invite_code(),
  icon_url text,
  created_at timestamptz not null default now()
);

create table if not exists project_members (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  user_id uuid not null,
  role text not null default 'member',
  created_at timestamptz not null default now()
);

create table if not exists songs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  title text not null,
  file_url text not null,
  file_size bigint,
  file_type text,
  duration integer,
  created_by uuid not null,
  created_at timestamptz not null default now()
);

create table if not exists song_versions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  song_id uuid not null references songs(id) on delete cascade,
  version_number integer not null,
  file_url text not null,
  original_file_url text,
  created_by uuid not null,
  created_at timestamptz not null default now()
);

create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  song_version_id uuid not null references song_versions(id) on delete cascade,
  body text not null,
  created_by uuid not null,
  created_at timestamptz not null default now()
);

create table if not exists play_history (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  song_version_id uuid not null references song_versions(id) on delete cascade,
  played_by uuid not null,
  played_at timestamptz not null default now()
);

create index if not exists project_members_project_id_idx on project_members(project_id);
create index if not exists songs_project_id_idx on songs(project_id);
create index if not exists song_versions_project_id_idx on song_versions(project_id);
create index if not exists comments_project_id_idx on comments(project_id);
create index if not exists play_history_project_id_idx on play_history(project_id);

create index if not exists song_versions_song_id_idx on song_versions(song_id);
create index if not exists comments_song_version_id_idx on comments(song_version_id);
create index if not exists play_history_song_version_id_idx on play_history(song_version_id);

alter table projects
  alter column invite_code set default generate_invite_code();

alter table projects enable row level security;
alter table project_members enable row level security;
alter table songs enable row level security;
alter table song_versions enable row level security;
alter table comments enable row level security;
alter table play_history enable row level security;

create policy projects_member_select
  on projects
  for select
  to authenticated
  using (
    exists (
      select 1 from project_members pm
      where pm.project_id = projects.id
        and pm.user_id = auth.uid()
    )
  );

create policy projects_member_modify
  on projects
  for update
  to authenticated
  using (
    exists (
      select 1 from project_members pm
      where pm.project_id = projects.id
        and pm.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from project_members pm
      where pm.project_id = projects.id
        and pm.user_id = auth.uid()
    )
  );

create policy projects_member_delete
  on projects
  for delete
  to authenticated
  using (
    exists (
      select 1 from project_members pm
      where pm.project_id = projects.id
        and pm.user_id = auth.uid()
    )
  );

create policy projects_member_insert
  on projects
  for insert
  to authenticated
  with check (auth.uid() is not null);

create policy project_members_member_select
  on project_members
  for select
  to authenticated
  using (
    exists (
      select 1 from project_members pm
      where pm.project_id = project_members.project_id
        and pm.user_id = auth.uid()
    )
  );

create policy project_members_member_modify
  on project_members
  for update
  to authenticated
  using (
    exists (
      select 1 from project_members pm
      where pm.project_id = project_members.project_id
        and pm.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from project_members pm
      where pm.project_id = project_members.project_id
        and pm.user_id = auth.uid()
    )
  );

create policy project_members_member_insert
  on project_members
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    or exists (
      select 1 from project_members pm
      where pm.project_id = project_members.project_id
        and pm.user_id = auth.uid()
    )
  );

create policy project_members_member_delete
  on project_members
  for delete
  to authenticated
  using (
    exists (
      select 1 from project_members pm
      where pm.project_id = project_members.project_id
        and pm.user_id = auth.uid()
    )
  );

create policy songs_member_access
  on songs
  for all
  to authenticated
  using (
    exists (
      select 1 from project_members pm
      where pm.project_id = songs.project_id
        and pm.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from project_members pm
      where pm.project_id = songs.project_id
        and pm.user_id = auth.uid()
    )
  );

create policy song_versions_member_access
  on song_versions
  for all
  to authenticated
  using (
    exists (
      select 1 from project_members pm
      where pm.project_id = song_versions.project_id
        and pm.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from project_members pm
      where pm.project_id = song_versions.project_id
        and pm.user_id = auth.uid()
    )
  );

create policy comments_member_access
  on comments
  for all
  to authenticated
  using (
    exists (
      select 1 from project_members pm
      where pm.project_id = comments.project_id
        and pm.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from project_members pm
      where pm.project_id = comments.project_id
        and pm.user_id = auth.uid()
    )
  );

create policy play_history_member_access
  on play_history
  for all
  to authenticated
  using (
    exists (
      select 1 from project_members pm
      where pm.project_id = play_history.project_id
        and pm.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from project_members pm
      where pm.project_id = play_history.project_id
        and pm.user_id = auth.uid()
    )
  );
