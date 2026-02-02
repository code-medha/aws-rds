# AWS Cloud Project

This is not a regular "hello-world" app, it's a near to production grade app that simulates the real-world deployment scenariors.

I always wanted to mimck the production-grade setup like how an application from the localhost is lifted and shifted to AWS. So, by taking an app and then deploying it to AWS would make sense to learn the AWS efficiently, because of the fact I will face the real world issues and how I go on to troublshooting them. This project is the accumaltion of all the AWS skills I learnt to deploy an application by simulating the production grade setup.

## Understand the Application Stack

This a 3-tier architecture micro-blogging platform application (ephemeral in nature) that allows users to post updates that automatically expire after a period of time. The application has the following stack:

- Frontend - ReactJS
- Backend - Python Flask 
- Feed Conversations - PostgreSQL


## Scope

The scope of AWS Cloud project is to deploy a 3-tier archieture application on AWS ECS.

## High-Level Architecture


![](/images/high-level.png)


## Application Demo


https://github.com/user-attachments/assets/25d4bd7f-0185-474c-b5b6-8ad7c03ddd15


## AWS Services Used

- ECS
- RDS
- ECR
- Cloudwatch
- Cognito
- ALB
- VPC
- Service Connect
- X-Ray
- Lambda
- Route 53
- Certificate Manager


## Other Services

- Honeycomb
- Rollbar


## Local Development with Docker

Containerization was my first step toward production-grade deployments or we can say it's an app deployment 101. I learned to write efficient Dockerfiles for both React and Flask applications, understanding concepts like layer caching, volume management, and using Docker Compose to orchestrate multi-container environments for local development.


For detailed documentation, see:
- [Containerization Overview](docs/docker-dev/docker-dev.md) - Understanding containers, Docker basics, and running the app locally
- [Backend Dockerization](docs/docker-dev/backend-docker.md) - Step-by-step guide to dockerize the Flask backend
- [Frontend Dockerization](docs/docker-dev/frontend-docker.md) - Step-by-step guide to dockerize the React frontend
- [Docker Compose Setup](docs/docker-dev/docker-compose.md) - Orchestrating the entire stack with docker-compose.dev.yml


## Observability


Understanding system behavior in production requires observability.  I instrumented Honeycomb for distributed tracing and Rollbar for error tracking. This hands-on experience taught me how to use OpenTelemetry to generate traces, create custom spans for specific operations, and simulate latency and errors to understand how observability tools capture and visualize system behavior.

For detailed documentation, see:
- [Observability Overview](docs/observe/scope.md) - Understanding observability concepts, traces, spans, and instrumentation
- [Honeycomb Instrumentation](docs/observe/honeycomb.md) - Configuring distributed tracing with OpenTelemetry
- [Rollbar Configuration](docs/observe/rollbar.md) - Setting up real-time error tracking and monitoring


## Local Postgres Implementation

I configured PostgreSQL locally using Docker and integrated it with the Flask backend. I learned to design database schemas, use Docker entrypoints for schema initialization, and write SQL queries with JOINs and JSON functions. Using psycopg as the database driver, I replaced mock data with real database queries, understanding how to structure queries that match API response formats.


For detailed documentation, see:
- [PostgreSQL Implementation Guide](docs/rds/rds.md) - Database schema design, Docker setup, and SQL query implementation


## Infrastructure as Code with Terraform

Before I start testing in production environments, I need to create resources in AWS. I used Terraform to provision the required AWS infrastructure such as VPC, RDS, ECR, ALB, ECS etc. I structured projects with modules for better organization and reusability.

For detailed documentation, see:
- [Terraform Implementation Guide](docs/terra/terraform.md) - Module-based structure, VPC, RDS, ECR, ALB, and ECR provisioning, and Terraform best practices.

## Production Database Setup (RDS)

After validating the database schema locally, I applied the same design to the AWS RDS PostgreSQL instance provisioned with Terraform. I created `schema-prod.sql` with the users and activities tables plus production seed data, and a `bin/db-setup` script that loads the schema, so schema deployment is repeatable and environment-driven.


## Authentication with Cognito and Lambda

I implemented authentication using AWS Cognito and kept the app’s `users` table in sync by adding a Cognito Post Confirmation Lambda trigger. When a user completes sign-up and confirmation, Cognito invokes the Lambda with the new user’s attributes; the Lambda inserts a row into the RDS `users` table with `display_name`, `email`, `handle`, and `cognito_user_id`. 

Because Lambda’s runtime doesn’t include psycopg2, I created a Lambda layer by building psycopg2 inside a container that matches Lambda’s environment, learning why native dependencies must be built for the same OS and architecture as the runtime.

For detailed documentation, see:
- [AWS Lambda Post Confirmation](docs/lambda/aws-lambda.md) — Cognito trigger, Lambda handler, and psycopg2 layer setup

## Dockerization for Production Envs


## ECR Implementation


## ECS

### Cluster Creation

### Task Defintion

### Service Creation





















