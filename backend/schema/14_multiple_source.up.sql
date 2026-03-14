alter table user_profiles
add column ws boolean not null default false;

alter table user_profiles
add column rd text;

alter table user_profiles
add column tb text;
