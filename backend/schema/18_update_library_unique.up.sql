alter table profile_library drop constraint fk_unique;

alter table profile_library add constraint fk_unique_library unique(profile_id, tmdb_id, type);
