# AWS Cloud Project

AWS Certifications are a great-way to get started with AWS and be aware of the services AWS offer. 
However doing AWS certifications is one thing, but I always felt i'm short the pratical implemetation of AWS skills i'm learning.
I always wanted to mimck the production-grade setup like how an application from the localhost is lifted and shifted to AWS. So, by taking an app and then deploying it to AWS would make sense to learn the AWS efficiently, because of the fact I will face the real world issues and how I go on to troublshooting them. This project is the accumaltion of all the AWS skills I learnt to deploy an application by simulating the production grade setup.

### Understand the Application Stack

This a 3-tier architecture micro-blogging platform application (ephemeral in nature) that allows users to post updates that automatically expire after a period of time. The application has the following stack:

- Frontend - ReactJS
- Backend - Python Flask 
- Feed Conversations - PostgreSQL

This is not a regular "hello-world" app, it's a near to production grade app that simulates the real-world deployment scenariors.


## Scope

The scope of AWS Cloud project is to deploy a 3-tier archieture application on AWS ECS.

## High-Level Architecture


![](/images/high-level.png)


## Complete Working Application Video

![](/vids/app.mp4)


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

## App Deployment 101? 

It all starts with Dockerizing the frontend and backend services.

## Dockerization for Local Developement

For detailed documentation, see:


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





















