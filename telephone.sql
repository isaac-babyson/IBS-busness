-- IBS Chat : connexion par numéro de téléphone + noms + badge bleu
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run
-- (après schema.sql)

-- 1. Nom affiché et badge bleu
alter table public.profiles add column if not exists display_name text check (char_length(display_name) <= 40);
alter table public.profiles add column if not exists verified boolean not null default false;

-- 2. À l'inscription, l'application enregistre le numéro (username) et le nom
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, display_name)
  values (new.id, lower(new.raw_user_meta_data->>'username'),
          nullif(left(trim(new.raw_user_meta_data->>'name'), 40), ''));
  return new;
end $$;

-- 3. BADGE BLEU pour le créateur (numéro 0840981930 = 243840981930).
--    À exécuter APRÈS avoir créé votre compte dans l'application.
--    (Cette ligne ne change rien tant que le compte n'existe pas.)
update public.profiles set verified = true where username = '243840981930';
