alter table user_profiles
add column trakt_token TEXT;

alter table user_profiles
add column trakt_refresh_token TEXT;

alter table user_profiles
add column trakt_expiry timestamptz;

alter table user_profiles
add column is_trakt_valid bool;

alter table user_profiles
add column last_sync_time timestamptz;
