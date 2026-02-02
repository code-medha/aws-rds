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


## Dockerization for Local Developement

Containerization was my first step toward production-grade deployments or we can say it's an app deployment 101. I learned to write efficient Dockerfiles for both React and Flask applications, understanding concepts like layer caching, volume management, and using Docker Compose to orchestrate multi-container environments for local development.


For detailed documentation, see:
- [Containerization Overview](docs/docker-dev/docker-dev.md) - Understanding containers, Docker basics, and running the app locally
- [Backend Dockerization](docs/docker-dev/backend-docker.md) - Step-by-step guide to dockerize the Flask backend
- [Frontend Dockerization](docs/docker-dev/frontend-docker.md) - Step-by-step guide to dockerize the React frontend
- [Docker Compose Setup](docs/docker-dev/docker-compose.md) - Orchestrating the entire stack with docker-compose.dev.yml


## Observability

Insturmented the app to get the traces and logs of the app.
Used Honeycomb and Rollbar.

For detailed documenation, see


## Local Postgres Implementation

Implemented Postgres implemetation for local development.

## Terraform

Started learning Terraform to create services in AWS which I would require for the upcoming configuration such VPC, RDS, ECR, ALB, ECS

For detailed documentation, see

## Production AWS RDS Postgres Implementation

After testing locally, we will start implementing the same schema.sql used in local dev to AWS RDS Postgres instance

For detailed information, see

## Create AWS Lambda Function for Cognito Service


## Dockerization for Production Envs


## ECR Implementation


## ECS

### Cluster Creation

### Task Defintion

### Service Creation





















