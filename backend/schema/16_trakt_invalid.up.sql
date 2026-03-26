alter table user_profiles add column trakt_profile jsonb;

update user_profiles set is_trakt_valid = false where is_trakt_valid = true;
