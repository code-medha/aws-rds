CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;


CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text NOT NULL,
  handle text NOT NULL,
  email text NOT NULL,
  cognito_user_id text NOT NULL,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

INSERT INTO public.users (display_name, handle, email, cognito_user_id)
VALUES
  ('Darshan Dev', 'darshandev' , 'ddev@gmail.com', 'MOCK'),
  ('Andrew Bayko', 'bayko' , 'abayko@gmail.com', 'MOCK'),
  ('Andrew Brown', 'andrewbrown' , 'abrown@gmail.com', 'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported from AWS RDS Postgres!',
    current_timestamp + interval '10 day'
  )
