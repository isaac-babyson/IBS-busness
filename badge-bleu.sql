-- IBS Chat : badge bleu (compte vérifié). À exécuter dans Supabase > SQL Editor.

-- 1. Ajoute la colonne "verified" (faux par défaut). Personne ne peut la modifier depuis l'application.
alter table public.profiles add column if not exists verified boolean not null default false;

-- 2. Après avoir créé VOTRE compte dans l'application (ex. nom d'utilisateur : isaac),
--    remplacez 'isaac' ci-dessous par votre nom d'utilisateur, puis exécutez cette ligne :
update public.profiles set verified = true where username = 'isaac';
