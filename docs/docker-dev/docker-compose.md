## Docker Compose

Previously, we ran frontend and backend as an indivual containers. But this method is not scalable. In real-world deployments, we often run multiple services—databases, caches, APIs—all together. So managing indivual contianers becomes difficult. To address these issues, `docker-compose` comes to the resue.

## What is Docker Compose

Docker Compose is a tool that let's you run multiple containers using a declartive approach in `.yml` format.
In a single `.yml` file you can define your entire app stack including app containers, databases, volumes, and networks. This approach makes the development, deployment, and management of containerized application.

## Let's write Docker Compose File for Dev Environment
As a best pratice,  it's common to create separate Compose files for development and production. It's not a must do. But it keeps the dev and prod requirements seperate. The goal here is to create a docker-compose file for dev environemnt. In the later stages, once we need to push to prod, we will create `docker-compose.prod.yml`.

`docker-compose.dev.yml`

```
services:
  backend-flask:
    env_file:
      - ./backend-flask/.env
    build: ./backend-flask
    ports:
      - "5000:5000"
    volumes:
      - ./backend-flask:/backend-flask
  frontend-react-js:
    env_file:
      - ./frontend-react-js/.env
    build: ./frontend-react-js
    ports:
      - "3000:3000"
    volumes:
      - ./frontend-react-js:/frontend-react-js
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

  dynamodb-local:
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal      

volumes:
  post:
    driver: local     
``` 

Let's understand the parameters of `docker-compose.yml` file:
- `services` - Under services you can define multiple containers. Every docker-compose file starts with services.
- `env _file` - Reference the .env file of your application.
- `build` - Points to the directory containing each service's Dockerfile.
- `ports` - Map host port with container port. It has {host_port}:{container_port} format
- `volumes` (under services level) - There are several falvours of volumes in docker. I will describe it in a seperate section.
- `volumes` (under root level) - Defines which named volumes exist in your Docker environment. Without it, Docker Compose wouldn’t know pgdata is a named volume.

## Docker Volumes

Dockers are ephimeral in nature. However, some applications needs to store the state of the application. In such cases, you need a persisent methods to store the data. This where Docker volumes shine.

Docker volumes are external storage managed by Docker. The volumes are stored outside the container’s writable layer.

There are 2 types of volumes you can define in your `docker-compose.yml`:

Bind Mounts: It maps (mirrors) the host path to the container. Use bind mounts for local developments where you want to see code changes instantly in the container without rebuilding the image every time. Format is `./host_path:/container_path`.

Named Volumes: These volumes are managed by Docker and stored in its own directory /var/lib/docker/volumes/.
These are specially designed for persistent data like databases etc. Format is `volume_name:/container_path`

Run the following command to run the docker compose file:
```
sudo docker compose -f docker-compose.dev.yml up -d
```

To rebuild the image along with running the docker compose file:
```
sudo docker compose -f docker-compose.dev.yml up -d --build
```

To stop the services:
```
sudo docker compose -f docker-compose.dev.yml down
```

There's an easy UI way to view logs and log in into containers from vscode. Install `Containers` extensions that is availabel in vscode.
1. Click `Containers` extension.
2. Right click on the container name.
3. Select **View Logs** to view logs.
4. Selectr **Attach Shell** to log in to the container.

To connect to the postgres database:
```
$ psql -h localhost -p 5436 -U postgres
```
To check the status to the DynamoDB database:
```
$ aws dynamodb list-tables --endpoint-url http://localhost:8000
```


We now have a development-ready docker-compose.dev.yml that spins up:

- Flask backend

- React frontend

- PostgreSQL

- Local DynamoDB

Volumes ensure persistence and live-reload during development.







