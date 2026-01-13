alter table users drop column trakt_refresh_token;
alter table users drop column expiry;
alter table users drop column trakt_auth_token;
alter table users drop column trakt_logged_in_at;


alter table users add column email text not null;
alter table users add column pwd_hash text not null;
