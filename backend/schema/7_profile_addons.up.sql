drop table series_progress;
drop table movie_progress;
drop table user_addons;
create table profile_addons(
  id serial primary key,
  profile_id int not null,
  mainfest_url text not null,
  enabled bool default true not null,
  added_at timestamptz default now() not null
);
alter table
  profile_addons
add
  constraint fk_addon_profile FOREIGN KEY(profile_id) REFERENCES user_profiles(id);
