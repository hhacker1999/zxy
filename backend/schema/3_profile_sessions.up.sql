alter table
  users drop column aio_manifest_url;
create table user_addons(
  id serial primary key,
  user_id int not null,
  addon_url text not null,
  added_at TIMESTAMPTZ default now() not null
);
create table profile_sessions(
  id serial primary key,
  session_id int not null,
  token text not null,
  expiry TIMESTAMPTZ not null,
  refresh_token text not null
);
alter table
  user_addons
add
  constraint fk_addon_user FOREIGN KEY (user_id) REFERENCES users(id);
alter table
  profile_sessions
add
  constraint fk_session_profile FOREIGN KEY (session_id) REFERENCES sessions(id);
