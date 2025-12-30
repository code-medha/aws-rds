# Dockerize the Frontend Framework for Production Env

For the React deveoplment envs, we use development server (npm start), which serves files dynamically with hot-reload and includes dev tools and source maps. All these parameters makes the image size larger. 

One of the important characterstics of production envs is to have a smaller image size. Why is this expectation? Because (write the explanation).

So How to reduce the image size?

* Use multi-stage #provide explaination
* distroless images #provide explaination


In this project, I will make use of multi-stage builds.


Create frontend-react-js/Dockerfile.prod file and add the following:
```
# Build Stage
FROM node:16.18 AS build

ARG REACT_APP_BACKEND_URL
ARG REACT_APP_AWS_PROJECT_REGION
ARG REACT_APP_AWS_COGNITO_REGION
ARG REACT_APP_AWS_USER_POOLS_ID
ARG REACT_APP_CLIENT_ID

ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL \
    REACT_APP_AWS_PROJECT_REGION=$REACT_APP_AWS_PROJECT_REGION \
    REACT_APP_AWS_COGNITO_REGION=$REACT_APP_AWS_COGNITO_REGION \
    REACT_APP_AWS_USER_POOLS_ID=$REACT_APP_AWS_USER_POOLS_ID \
    REACT_APP_CLIENT_ID=$REACT_APP_CLIENT_ID


WORKDIR /frontend-react-js

# Copy package files first for better layer caching
COPY package*.json .

RUN npm ci

COPY . .

# Build the application
RUN npm run build

# Production Image
FROM nginx:1.23.3-alpine

# Copy built assets from build stage
COPY --from=build /frontend-react-js/build /usr/share/nginx/html

# Copy nginx configuration (create this file)
COPY --from=build /frontend-react-js/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
```

Why ARG and ENV?

React reads environment variables at BUILD TIME, not runtime. Values get baked into JS files. ECS environment variables won’t work for React frontend.

Why do I need a nginx here? Why can't I serve the React application directly?

React is not a backend application. After npm run build, it becomes static files (HTML, CSS, JS). These files do not need Node.js to run. They need a web server to serve static content. nginx servers the purpose here.

## Nginx Configuration

since we are using ngnix, we need to provide the configuration details. It is provided using nginx.conf file.

Create frontend-react-js/nginx.conf file and add the following lines:
```
# Set the worker processes
worker_processes 1;

# Set the events module
events {
  worker_connections 1024;
}

# Set the http module
http {
  # Set the MIME types
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  # Set the log format
  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

  # Set the access log
  access_log  /var/log/nginx/access.log main;

  # Set the error log
  error_log /var/log/nginx/error.log;

  # Set the server section
  server {
    # Set the listen port
    listen 3000;

    # Set the root directory for the app
    root /usr/share/nginx/html;

    # Set the default file to serve
    index index.html;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to redirecting to index.html
        try_files $uri $uri/ $uri.html /index.html;
    }

    # Set the error page
    error_page  404 /404.html;
    location = /404.html {
      internal;
    }

    # Set the error page for 500 errors
    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
      internal;
    }
  }
}
```
The complete flow:

1. docker-compose.prod.yml args: 
   REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}
   ↓ (passes value, e.g., "https://api.example.com")
   
2. Dockerfile ARG REACT_APP_BACKEND_URL
   ↓ (receives "https://api.example.com")
   
3. Dockerfile ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
   ↓ (copies "https://api.example.com" to ENV)
   
