## Creating  Elastic Container Registry (ECR) repo and push image


Create a base image for Python

The reason is that pulling a Docker image from Docker Hub might sometimes encounter connectivity issues or rate limits on image pull requests. 

So better way of handling it is pull the Python image from Docker and push it into ECR and then reference that one in `Dockerfile.prod`. This eliminates the Docker hub being a point of failure.


How-to

create an ECR repo for Python base image:
```
$ aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
``` 


Pull the Python base docker image:
```
$ docker pull python:3.10-slim-buster
```

tag the image:
```
$ docker tag python:3.10-slim-buster <>.dkr.ecr.<>.amazonaws.com/cruddur-python:3.10-slim-buster
```

Push the image:
```
$ docker push <>.dkr.ecr.<>.amazonaws.com/cruddur-python:3.10-slim-buster
```

Once the image is pushed, go to AWS web console, select ECR > Images > copy the image URI.

Instead of hardcoding the ECR image URI directly in `Dockerfile.prod` (which would expose your AWS account ID in the repository), we'll use an environment variable to pass it during the build process.

### Why use environment variables?

1. **Security**: Keeps sensitive information (like AWS account IDs) out of version control
2. **Flexibility**: Allows different ECR registries for different environments without code changes
3. **Best practice**: Separates configuration from code

### Why a root-level .env file?

You might wonder why we can't use the existing `/backend-flask/.env.prod` file. The reason is:

- `env_file` in `docker-compose.prod.yml` is only available at **container runtime**, not during build time
- `ARG` directives in Dockerfiles are evaluated at **build time**, before the container runs
- Docker Compose automatically reads `.env` files from the same directory as the compose file for variable substitution
- Therefore, we need a root-level `.env` file (next to `docker-compose.prod.yml`) that Docker Compose can read during the build process

### Implementation Steps

1. **Create a `.env` file at the root level** (same directory as `docker-compose.prod.yml`):

```
ECR_REGISTRY=<your-account-id>.dkr.ecr.<region>.amazonaws.com/cruddur-python:3.10-slim-buster
```

Replace `<your-account-id>` and `<region>` with your actual AWS account ID and region.

2. **Update `Dockerfile.prod`** to accept the registry as a build argument:

```dockerfile
ARG ECR_REGISTRY

FROM ${ECR_REGISTRY}

WORKDIR /backend-flask

COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

# Set production environment
ENV FLASK_ENV=production
ENV PYTHONUNBUFFERED=1

EXPOSE 5000

# Remove --reload flag for production
CMD [ "python3", "-m", "flask", "run", "--host=0.0.0.0", "--port=5000" ]
```

3. **Update `docker-compose.prod.yml`** to pass the build argument:

```yaml
services:
  backend-flask:
    env_file:
      - ./backend-flask/.env.prod
    build:
      context: ./backend-flask
      dockerfile: Dockerfile.prod
      args:
        ECR_REGISTRY: "${ECR_REGISTRY}"
    ports:
      - "5000:5000"
    volumes:
      - ./backend-flask:/backend-flask
```

Docker Compose will automatically substitute `${ECR_REGISTRY}` with the value from the root-level `.env` file during the build process.

## Create a log group for the ECS

Create a log group named `cruddur` with 1 day retention setting.


