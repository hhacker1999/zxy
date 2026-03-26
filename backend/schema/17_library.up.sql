create table profile_library (
id serial primary key,
profile_id int not null,
tmdb_id int not null,
type varchar(5) not null,
created_at timestamptz default now() not null
);

alter table profile_library add constraint fk_profile_library FOREIGN KEY (profile_id)
  REFERENCES user_profiles(id);

alter table profile_library add constraint fk_unique unique(id, tmdb_id, type);
