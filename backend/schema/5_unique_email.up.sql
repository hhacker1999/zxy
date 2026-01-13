alter table users 
add constraint unique_email unique(email);

create table user_profiles(
  id serial primary key,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  name text not null,
  pin_hash text,
  user_id int not null
);


alter table profile_sessions add column profile_id int not null;

alter table profile_sessions add constraint fk_profile_session FOREIGN KEY(profile_id) REFERENCES user_profiles(id);
