create table movie_progress(
  id serial primary key,
  user_id integer not null,
  movie_id integer not null,
  progress Numeric(5, 2) default 0,
  is_watched bool default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table movie_progress add constraint
fk_user_movie FOREIGN KEY(user_id) REFERENCES users(id);

alter table movie_progress add constraint
unique_movie_user unique(user_id, movie_id);

create table series_progress(
  id serial primary key,
  user_id integer not null,
  series_id integer not null,
  season integer not null default 0,
  episode integer not null default 1,
  progress Numeric(5, 2) default 0,
  is_watched bool default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table series_progress add constraint
fk_user_series FOREIGN KEY(user_id) REFERENCES users(id);

alter table series_progress add constraint
unique_series_user_season_episode unique(user_id, series_id, season, episode);

alter table users add column trakt_refresh_token varchar(70),add column trakt_auth_token varchar(70),
add column expiry integer,add column trakt_logged_in_at timestamptz;
