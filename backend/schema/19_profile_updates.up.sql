alter table user_profiles drop column tb;
alter table user_profiles drop column rd;
alter table user_profiles drop column ws;
alter table user_profiles drop column debrid_type;
alter table user_profiles drop column debrid_key;


alter table user_profiles add column services jsonb;
alter table user_profiles add column presets text[];
