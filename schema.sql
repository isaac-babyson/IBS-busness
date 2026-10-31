-- IBS Chat : à coller dans Supabase > SQL Editor > New query, puis "Run"

-- 1. Profils (un par utilisateur)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (username ~ '^[a-z0-9_]{3,20}$'),
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "profils visibles par les connectés" on public.profiles
  for select to authenticated using (true);

-- Crée automatiquement le profil à l'inscription
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username)
  values (new.id, lower(new.raw_user_meta_data->>'username'));
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. Messages (texte ou vocal)
create table if not exists public.messages (
  id bigint generated always as identity primary key,
  sender uuid not null references public.profiles(id) default auth.uid(),
  receiver uuid not null references public.profiles(id),
  body text check (char_length(body) <= 2000),
  audio_path text,
  audio_secs int,
  created_at timestamptz default now(),
  check (body is not null or audio_path is not null)
);
create index if not exists messages_sender_idx on public.messages(sender, created_at desc);
create index if not exists messages_receiver_idx on public.messages(receiver, created_at desc);
alter table public.messages enable row level security;
create policy "lire ses messages" on public.messages
  for select to authenticated using (auth.uid() in (sender, receiver));
create policy "envoyer en son nom" on public.messages
  for insert to authenticated with check (auth.uid() = sender);

-- Messages en temps réel
alter publication supabase_realtime add table public.messages;

-- 3. Stockage des messages vocaux (privé)
insert into storage.buckets (id, name, public) values ('voices', 'voices', false)
  on conflict (id) do nothing;
create policy "envoyer un vocal dans son dossier" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'voices' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "écouter un vocal" on storage.objects
  for select to authenticated using (bucket_id = 'voices');
