# Creating Elastic Container Registry (ECR) Repositories and Pushing Images

When I started deploying my containerized applications to AWS ECS, I realized that ECS needs a place to pull Docker images from. While Docker Hub is the default public registry, I learned that using AWS ECR (Elastic Container Registry) provides better integration with AWS services and eliminates external dependencies.

> **What is ECR?**
>
> AWS ECR is a fully managed Docker container registry that makes it easy to store, manage, and deploy Docker container images. It's integrated with AWS ECS, so your ECS tasks can pull images directly from ECR without needing external registry access.

## Why Use ECR Instead of Docker Hub?

Initially, I thought I could just reference Docker Hub images in my `Dockerfile.prod` files. However, I discovered several reasons why using ECR is a better approach:

- **Docker Hub rate limits**: Pulling images from Docker Hub might encounter connectivity issues or rate limits on image pull requests, especially during high-traffic deployments.
- **AWS integration**: ECR integrates seamlessly with ECS, IAM, and other AWS services.
- **Security**: Images stored in ECR can be encrypted and access can be controlled through IAM policies.
- **Reliability**: Eliminates Docker Hub as a point of failure in your deployment pipeline.

For this project, I decided to use ECR for both base images and application images to ensure a reliable and integrated deployment process.

---

## Creating an ECR Repository for Python Base Image

When I first set up my production Dockerfiles, I noticed they were pulling the Python base image directly from Docker Hub. I realized this could become a point of failure, so I decided to pull the Python image from Docker Hub once, push it to ECR, and then reference the ECR image in my `Dockerfile.prod`. This eliminates Docker Hub as a dependency.

> **Why create a separate repository for the base image?**
>
> By storing the Python base image in ECR, I ensure that even if Docker Hub is unavailable, my builds won't fail. This is especially important for production deployments where reliability is critical.

### Understanding Image Tag Mutability

When creating an ECR repository, you need to specify `--image-tag-mutability`. I chose `MUTABLE` because:

- **MUTABLE**: Allows you to push new images with the same tag (overwrites existing images). This is useful during development and allows you to reuse tags like `latest`.
- **IMMUTABLE**: Once a tag is created, it cannot be overwritten. This is more secure for production but requires careful tag management.

For this project, I'm using `MUTABLE` to allow flexibility during development and testing.

### Implementation Steps

1. Create an ECR repository for the Python base image:
```bash
$ aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
```

2. Authenticate Docker to ECR:
```bash
$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

Replace `<AWS_ACCOUNT_ID>` with your actual AWS account ID.

3. Pull the Python base Docker image:
```bash
$ docker pull python:3.10-slim-buster
```

4. Tag the image with your ECR repository URI:
```bash
$ docker tag python:3.10-slim-buster <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster
```

Replace `<AWS_ACCOUNT_ID>` with your actual AWS account ID.

5. Push the image to ECR:
```bash
$ docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster
```

### Verification

After pushing, verify the image exists in ECR:
```bash
$ aws ecr describe-images --repository-name cruddur-python --region us-east-1
```

You should see the image with tag `3.10-slim-buster` listed.

---

## Creating an ECR Repository for Backend-Flask

Now that I had the base image in ECR, I needed to create a repository for my backend Flask application. This repository will store the production-ready Docker image that ECS will pull and run.

### Implementation Steps

1. Create an ECR repository for backend-flask:
```bash
$ aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```

2. Authenticate Docker to ECR (if you haven't already in this session):
```bash
$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

3. Build the production Docker image:
```bash
$ cd backend-flask
$ docker build -f Dockerfile.prod -t backend-flask .
```

4. Tag the image with your ECR repository URI:
```bash
$ docker tag backend-flask:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/backend-flask:latest
```

5. Push the image to ECR:
```bash
$ docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/backend-flask:latest
```

### Verification

Verify the image was pushed successfully:
```bash
$ aws ecr describe-images --repository-name backend-flask --region us-east-1
```

You should see the image with tag `latest` in the repository.

---

## Creating an ECR Repository for Frontend-React-JS

Similar to the backend, I needed a separate ECR repository for the frontend React application. This keeps the images organized and allows independent versioning of frontend and backend deployments.

### Implementation Steps

1. Create an ECR repository for frontend-react-js:
```bash
$ aws ecr create-repository \
  --repository-name frontend-react-js \
  --image-tag-mutability MUTABLE
```

2. Authenticate Docker to ECR (if you haven't already in this session):
```bash
$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

3. Build the production Docker image:
```bash
$ cd frontend-react-js
$ docker build \
--build-arg REACT_APP_BACKEND_URL="$REACT_APP_BACKEND_URL" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="$REACT_APP_AWS_USER_POOLS_ID" \
--build-arg REACT_APP_CLIENT_ID="$REACT_APP_CLIENT_ID" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```

4. Tag the image with your ECR repository URI:
```bash
$ docker tag frontend-react-js:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/frontend-react-js:latest
```

5. Push the image to ECR:
```bash
$ docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/frontend-react-js:latest
```

### Verification

Verify the image was pushed successfully:
```bash
$ aws ecr describe-images --repository-name frontend-react-js --region us-east-1
```

You should see the image with tag `latest` in the repository.

---

## Complete Workflow Summary

Here's the complete workflow I followed for setting up ECR:

1. **Base Image Setup**:
   - Create ECR repository for Python base image
   - Pull Python image from Docker Hub
   - Tag and push to ECR
   - Update `Dockerfile.prod` to reference ECR image

2. **Application Images**:
   - Create ECR repositories for backend and frontend
   - Build production Docker images
   - Tag images with ECR URIs
   - Push images to ECR

3. **Infrastructure**:
   - Create CloudWatch log group for ECS logs

4. **ECS Integration**:
   - Reference ECR image URIs in task definitions
   - Ensure ECS task execution role has ECR pull permissions

This setup ensures that all my container images are stored in AWS, eliminating external dependencies and providing better integration with the AWS ecosystem.



## Creating a CloudWatch Log Group for ECS

ECS needs a CloudWatch log group to store container logs. Without this, ECS tasks might fail to start because they can't write logs.

> **Why do we need a log group?**
>
> ECS containers write their stdout and stderr to CloudWatch Logs. The log group must exist before the task starts, otherwise the task will fail. Setting a retention period helps manage costs by automatically deleting old logs.

### Implementation Steps

Create a log group named `cruddur` with 1 day retention setting:
```bash
$ aws logs create-log-group --log-group-name cruddur
$ aws logs put-retention-policy --log-group-name cruddur --retention-in-days 1
```

The 1-day retention means logs older than 1 day will be automatically deleted, which helps manage CloudWatch Logs costs.

### Verification

Verify the log group was created:
```bash
$ aws logs describe-log-groups --log-group-name-prefix cruddur
```

---
