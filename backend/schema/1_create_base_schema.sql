create table users(
  id serial primary key,
  user_id uuid unique not null,
  name varchar(150) not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  aio_manifest_url text not null
);

create table sessions(
 id serial primary key,
 user_id integer not null,
 token varchar(200) not null,
 expiry timestamptz not null
);

alter table sessions add constraint 
fk_session_user FOREIGN KEY(user_id) 
REFERENCES users(id);

