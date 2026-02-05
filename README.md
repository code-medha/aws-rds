# AWS Cloud Project

This isn’t a “hello-world” app, it’s a near–production-grade setup that mirrors how real applications are lifted from localhost to AWS.

I wanted to learn AWS by doing what teams actually do. Take an app, deploy it end-to-end, and run into the same issues they do. By simulating a production-style deployment, I get to face real-world problems and learn how to troubleshoot them. This project is the result of that approach, a 3-tier micro-blogging application deployed on AWS, built step by step from containerization to ECS, with the kind of setup you’d see in a real environment.

## Understand the Application Stack

This a 3-tier architecture micro-blogging platform application (ephemeral in nature) that allows users to post updates that automatically expire after a period of time. The application has the following stack:

- Frontend - ReactJS
- Backend - Python Flask 
- Feed Conversations - PostgreSQL

## Scope

The goal of this AWS Cloud project is to deploy this 3-tier application on AWS ECS and demonstrate production-grade practices along the way.

## High-Level Architecture


![](/images/high-level.png)


## Application Demo


https://github.com/user-attachments/assets/25d4bd7f-0185-474c-b5b6-8ad7c03ddd15


## AWS Services Used

- ECS (Fargate)
- RDS (PostgresSQL)
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
- [AWS Lambda Post Confirmation](docs/lambda/aws-lambda.md) - Cognito trigger, Lambda handler, and psycopg2 layer setup


## Production-Grade Docker Images (Frontend & Backend)

After getting the app running locally in containers, I focused on building production-ready Docker images for both the React frontend and Flask backend. 

For the frontend, I learned to use multi-stage builds with nginx to turn the React app into a small, fast static site image, optimized for size, security, and startup time. 

For the backend, I created a separate production Dockerfile that removes dev-only features like `--reload`, switches `FLASK_ENV` to `production`, uses `--no-cache-dir` for smaller images, and pulls its base image from ECR instead of Docker Hub for better reliability and integration with AWS.

For detailed documentation, see:
- [Production Dockerization (Frontend)](docs/docker-prod/prod-docker-frontend.md) - Multi-stage builds, nginx, and image size optimization
- [Production Dockerization (Backend)](docs/docker-prod/prod-docker-backend.md) - Production Flask image, ECR base image, and runtime best practices


## ECR Implementation

I implemented ECR as the container registry layer for this project. I learnt how ECS pulls images and how IAM controls access to private registries. I created separate ECR repos for a Python base image, the Flask backend, and the React frontend. Then built, tagged, and pushed production images so ECS can deploy them consistently.

For detailed documentation, see:
- [ECR Setup](docs/ecr/ecr.md) - repos for base/app images, Docker login, tag/push, and CloudWatch log group for ECS

## Application Deployment on Amazon ECS (Fargate)

I used Amazon ECS with Fargate to run the frontend and backend as separate services, wired to the images stored in ECR. Each task definition uses `awsvpc` networking, CloudWatch logging, and service-specific health checks, and integrated with an Application Load Balancer. Both services are discoverable via ECS Service Connect.


For more infromation, see:
- Task Defintions
    - [Backend task definition](aws/task-definition/backend-flask.json)
    - [Frontend task definition](aws/task-definition/frontend-react-js.json)

- Services

    - [Backend ECS service](aws/ecs-service/service-backend.json)
    - [Frontend ECS service](aws/ecs-service/service-frontend.json)
























