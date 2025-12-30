## Creating  Elastic Container Registry (ECR) repo and push image


Create a base image for Python

The reason is that pulling a Docker image from Docker Hub might sometimes encounter connectivity issues or rate limits on image pull requests. 

So better way of handling it is pull the Python image from Docker and push it into ECR and then reference that one in `Dockerfile.prod`. This eliminates the Docker hub being a point of failure.


How-to

1. create an ECR repo for Python base image:
```
$ aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
``` 


2. Pull the Python base docker image:
```
$ docker pull python:3.10-slim-buster
```

3. Tag the image:
```
$ docker tag python:3.10-slim-buster <>.dkr.ecr.<>.amazonaws.com/cruddur-python:3.10-slim-buster
```

4. Push the image:
```
$ docker push <>.dkr.ecr.<>.amazonaws.com/cruddur-python:3.10-slim-buster
```

## Create a log group for the ECS

Create a log group named `cruddur` with 1 day retention setting.


## Create an ECR Repo for Backend-Flask

How-to

1. $ aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE

2. $ docker build -f Dockerfile.prod -t backend-flask . 

3. $ docker tag backend-flask:latest <>.dkr.ecr.us-east-1.amazonaws.com/backend-flask:latest

4. $ docker push <>.dkr.ecr.us-east-1.amazonaws.com/backend-flask:latest

## Create an ECR Repo for frontend-react-js

How-to

1. $ aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE

2. $ docker build -f Dockerfile.prod -t frontend-react-js .

3. $ docker tag frontend-react-js:latest <>.dkr.ecr.us-east-1.amazonaws.com/frontend-react-js:latest

4. $ docker push <>.dkr.ecr.us-east-1.amazonaws.com/frontend-react-js:latest
