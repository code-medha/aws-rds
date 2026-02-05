# AWS RDS Implementation Project

In this project, I will configure the application with AWS RDS Postgres database.

First we will configure the containerzied Postgres Docker image for testing purpose and then for production purpose we will configure AWS RDS Postgres.


## Postgres Docker Image:

Before we fire up the `docker-compose.dev.yml`, we must ensure that postgres service is added. Add the following to your `docker-compose.dev.yml`

```
...
...
...
  post:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_DB=cruddur
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5436:5432'
    volumes: 
      - post:/var/lib/postgresql/data
      - ./backend-flask/db/schema.sql:/docker-entrypoint-initdb.d/schema.sql

...
...
...

volumes:
  post:
    driver: local
```

Then run the docker compose command:
```
$ docker compose -f ./docker-compose.dev.yml up -d --build
```

Connect to PostgreSQL container:
```
$ psql "postgresql://postgres:password@localhost:5436/postgres"
```

Next step is to create schema.sql file.


## `schema.sql` file

Before we create a `schema.sql` file, let's understand what is a `schema.sql` file. 

> So, What is a `schema.sql`?

A schema.sql is a SQL script that defines the complete structure of your database. Basically it's a blueprint of your database architecture. Using `schema.sql` you can create:

- Databases
- Tables
- Columns and data types
- Constraints (primary keys, foreign keys, unique constraints)
- Indexes
- Functions
- Triggers

> Why we need a `schema.sql` file? 

`schema.sql` file is kind a documentation of database. Anyone can create the exact same database by importing it. It serves as a clear reference of how your DB is organized - useful for developers, DBAs, and auditors. Also, it’s easy to recreate the structure if your database gets corrupted or moved to another environment.

> What will happen if we don't use `schema.sql` file?

You have to manually create tables, indexes, and constraints using raw SQL commands. That’s error-prone and inconsistent.

## Table Design

To create a `schema.sql` file we need to have a solid understanding of the table design. 

For our application, we will have two tables - users and activites. 

### Activities Table Design Decisions:

For activites table, the schema columns directly mirror the API response structure. Each property in the OpenAPI schema becomes a database column.

```
Activity:
  properties:
    uuid: string
    display_name: string  
    handle: string
    message: string
    replies_count: integer
    reposts_count: integer
    likes_count: integer
    created_at: string
    expires_at: string 
```

Activites table stores each post, tweet, or message a user creates and includes the following columns:

| Column                   | Type        | Description                                                                                                  |
| ------------------------ | ----------- | ------------------------------------------------------------------------------------------------------------ |
| `uuid`                   | `UUID`      | Unique ID for the activity.                                                                                  |
| `user_uuid`              | `UUID`      | The user who created this activity — should match a `users.uuid`.                                            |
| `message`                | `text`      | The content of the post.                                                                                     |
| `replies_count`          | `integer`   | Number of replies (default `0`).                                                                             |
| `reposts_count`          | `integer`   | Number of reposts or shares.                                                                                 |
| `likes_count`            | `integer`   | Number of likes.                                                                                             |
| `reply_to_activity_uuid` | `integer`   | (optional) ID of the post this one replies to. *(Should ideally be UUID, not integer — we’ll discuss that!)* |
| `expires_at`             | `TIMESTAMP` | Optional time when the post expires.                                                                         |
| `created_at`             | `TIMESTAMP` | Auto-filled creation date.                                                                                   |
    
### Users Table Design Decisions:

For users table, the following parameters are considered:

- cognito_user_id: AWS Cognito integration requirement
- handle: Unique username for @mentions
- display_name: User-friendly name for UI display
- email: Authentication requirement

Users table stores the identity information about each registered user (cognito) and includes the following columns:

| Column            | Type        | Description                                                                                      |
| ----------------- | ----------- | ------------------------------------------------------------------------------------------------ |
| `uuid`            | `UUID`      | Unique ID for each user; `DEFAULT uuid_generate_v4()` auto-generates one. Acts as `PRIMARY KEY`. |
| `display_name`    | `text`      | The user’s full name.                                                                            |
| `handle`          | `text`      | The user’s unique username (like `@andrewbrown`).                                                |
| `email`           | `text`      | User’s email address.                                                                            |
| `cognito_user_id` | `text`      | ID from AWS Cognito (if integrated with AWS authentication).                                     |
| `created_at`      | `TIMESTAMP` | Stores the exact date/time the record was created. Uses `current_timestamp` by default.          |


## Creating a `schema.sql` file

Based on the table design, let's create a `schema.sql` for our application.

```
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
  replies_count integer  0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

INSERT INTO public.users (display_name, handle, email, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' , 'abrown@gmail.com', 'MOCK'),
  ('Andrew Bayko', 'bayko' , 'abayko@gmail.com', 'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```


## Postgres Key Concepts

> CREATE EXTENSION

Extensions are like plugins that add new capabilities to PostgreSQL. You can install these plugins based on your requirements. Here we are installing an extension called `uuid-ossp`, which generate UUIDs (Universally Unique Identifiers)

> PRIMARY KEY

Primary Key ensures each row is unique and acts as an identifier.

> DEFAULT

Default values simplify inserts (Postgres fills them automatically).

> NOT NULL

NOT NULL ensures these columns must have values.


## Loading the `schema.sql` into Database

We can write bash scripts to connect to the database, create a table, and load the schema. However, the PostgreSQL docker image provides a Docker entrypoint, which gets executed ONLY ON FIRST RUN when the database is initialized. We can use the Docker entrypoint to load the schema.


THe following line in the `docker-compose.dev.yml` for post service, load the schema:
```
- ./backend-flask/db/schema.sql:/docker-entrypoint-initdb.d/schema.sql
```

## `psycopg`

Python Flask itself cannot directly communicate with databases. It needs a database driver that acts as a bridge between Python code and a PostgreSQL database. `psycopg` is a PostgreSQL database adapter for Python that connects to the PostgreSQL server and senda SQL commands.


### Install the `psycopg` Python Package

Add the following package to requirements.txt:
```
psycopg[binary, pool]
```

### Import statements to `home_activities.py`:
```
from psycopg_pool import ConnectionPool
```

### `psycopg` Implementation to Return Activity data

```
    with pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql)
        activities = cur.fetchone()
    
    print(activities[0])
    return activities[0] if activities and activities[0] is not None else []
```

 `return activities[0] if activities and activities[0] is not None else []]` will handle error cases that could crash your application:

- if only activities[0]  # TypeError: 'NoneType' object is not subscriptable

- if only activities = None  # returns (None,) if your query returns NULL


### Writng a SQL Query

Replace the mock data with the sql query (refer to `home_activities.py):
```
...
...
...

    sql = """
    SELECT COALESCE(
      array_to_json(array_agg(row_to_json(row_results))),
      '[]'::json
    ) as activities
    FROM (
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
    ) row_results
    """
    
    with pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql)
        activities = cur.fetchone() 
    
    print(activities[0])
    return activities[0] if activities and activities[0] is not None else []
 ```

 **Line-by-Line Explanation of SQL QUERY**

 ```
 SELECT COALESCE(
  array_to_json(array_agg(row_to_json(row_results))),
  '[]'::json
) as activities
```

`COALESCE()`: This function returns the first non-null value from its arguments. If there are no activities, it returns an empty JSON array [] instead of NULL

`as activities`: Renames the result column to "activities"

--------

```
FROM (
  SELECT
```

This starts a subquery - a query within the main query. The data inside the parentheses will be processed first.

---------

```
    activities.uuid,
    users.display_name,
    users.handle,
    activities.message,
    activities.replies_count,
    activities.reposts_count,
    activities.likes_count,
    activities.reply_to_activity_uuid,
    activities.expires_at,
    activities.created_at
```

Selects specific columns from two tables: activities and users.

----------
```
  FROM public.activities
  LEFT JOIN public.users ON users.uuid = activities.user_uuid
```

`FROM public.activities`: Main table we're querying from.

`LEFT JOIN`: Includes all records from activities table, even if there's no matching user.

`ON users.uuid = activities.user_uuid`: matches user UUID in activities to user table

----------

```
) row_results
```

row_results: Names the subquery result so we can reference it in the outer query

----------


## Testing the Local Postgres Implementation


Run the following command to run the docker compose file:
```
$ docker compose -f ./docker-compose.dev.yml up -d --build
```

Hurray!!! As you can see the database is connected your application and can read the data.

![](../../images/300-local.png)
