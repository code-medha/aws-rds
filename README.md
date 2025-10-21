# AWS RDS Implementation Project

In this project I will configure the application with AWS RDS Postgres database.

First we will configure the local containerzied RDS instance for testing purpose and then for production purpose we will configure AWS RDS Postgres.


## Logging into Containerzied Postgres Database:

Before we fire up the `docker-compose.dev.yml`, we must ensure that postgres service is added. Add the following to your `docker-compose.dev.yml`

```
...
...
...
  post:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5436:5432'
    volumes: 
      - post:/var/lib/postgresql/data

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

`schema.sql` file is kind a documentation of database. Anyone can create the exact same database by importing it. It serves as a clear reference of how your DB is organized — useful for developers, DBAs, and auditors. Also, it’s easy to recreate the structure if your database gets corrupted or moved to another environment.

> What will happen if we don't use `schema.sql` file?

You have to manually create tables, indexes, and constraints using raw SQL commands. That’s error-prone and inconsistent.

## Creating a `schema.sql` file

As we are already using the PostgreSQL container, we can make use of ENTRYPOINT command which reads the `schema.sql` file when is container is up and running. This method proves to be efficient because PostgreSQL containers are ephimeral in nature, so anytime you restart the container, the database configuration is wiped out and a fresh new container is created.






