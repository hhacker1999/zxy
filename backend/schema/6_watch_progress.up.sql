create table watch_progress(
  id serial primary key,
  user_id int not null,
  profile_id int not null,
  media_id varchar(15) not null,
  progress Numeric(5, 2) not null,
  is_watched bool default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table watched (
  id serial primary key,
  user_id int not null,
  profile_id int not null,
  media_id varchar(10) not null,
  created_at timestamptz not null default now()
);
alter table
  watch_progress
add
  constraint progress_unique unique(user_id, media_id, profile_id);
alter table
  watched
add
  constraint watched_unique unique(user_id, media_id, profile_id);
alter table
  watch_progress
add
  constraint fk_progress_user FOREIGN KEY(user_id) REFERENCES users(id);
alter table
  watch_progress
add
  constraint fk_progress_profile FOREIGN KEY(profile_id) REFERENCES user_profiles(id);
alter table
  watched
add
  constraint fk_watched_user FOREIGN KEY(user_id) REFERENCES users(id);
alter table
  watched
add
  constraint fk_watched_profile FOREIGN KEY(profile_id) REFERENCES user_profiles(id);
