# Dockerizing the Frontend Framework for Production Environment

For development environments, we use `npm start`, which runs a development server that serves files dynamically with hot-reload capabilities and includes dev tools and source maps. While this is perfect for development, all these features significantly increase the Docker image size.

**Why does image size matter in production?**

Smaller Docker images are crucial for production environments for several reasons:

- **Faster deployments**: Smaller images transfer faster over the network, reducing deployment time, especially important when pulling images from ECR to ECS tasks across multiple availability zones.
- **Reduced storage costs**: ECR charges based on storage, so smaller images mean lower costs.
- **Improved security**: Smaller images have a smaller attack surface - fewer packages mean fewer potential vulnerabilities.
- **Better resource utilization**: Smaller images consume less disk space on ECS hosts, allowing more tasks to run on the same infrastructure.
- **Faster container startup**: Less data to extract means containers start faster, improving application responsiveness.

## How to Reduce Image Size?

There are several strategies to reduce Docker image size:

### Multi-Stage Builds

Multi-stage builds allow you to use multiple `FROM` statements in a single Dockerfile. Each `FROM` instruction starts a new build stage. You can selectively copy artifacts from one stage to another, leaving behind everything you don't need in the final image.

How it works:
- **Build stage**: Contains all the build tools (Node.js, npm, source code, node_modules) needed to compile your application.
- **Production stage**: Contains only the runtime dependencies and the compiled output.

Why it's effective:
- The final image doesn't include Node.js, npm, source code, or development dependencies - only the compiled static files and a lightweight web server.
- This can reduce image size from several hundred MBs to just tens of MBs.

### Distroless Images

Distroless images contain only your application and its runtime dependencies. They don't include package managers, shells, or other programs you'd find in a standard Linux distribution.

Why use distroless?
- **Security**: No shell means attackers can't easily get shell access even if they compromise your application.
- **Size**: Smaller base images because they exclude unnecessary OS components.
- **Simplicity**: Forces you to include only what's absolutely necessary.

For this project, I chose to use **multi-stage builds** because they provide an excellent balance between size reduction and flexibility, while still allowing me to use a well-maintained base image like `nginx:alpine`.

---

## Creating the Production Dockerfile

Create `frontend-react-js/Dockerfile.prod` and add the following configuration:

```dockerfile
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

RUN npm install

COPY . .

# Build the application
RUN npm run build

# Production Image
FROM nginx:1.23.3-alpine

# Copy built assets from build stage
COPY --from=build /frontend-react-js/build /usr/share/nginx/html

# Copy nginx configuration
COPY --from=build /frontend-react-js/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
```

### Understanding the Build Stage

The first stage (`FROM node:16.18 AS build`) is where all the compilation happens:

1. **ARG declarations**: These receive build-time arguments passed from `docker-compose.prod.yml` or the `docker build` command.
2. **ENV declarations**: These convert ARG values into environment variables that React's build process can access.
3. **Layer caching optimization**: By copying `package*.json` first and running `npm install` before copying the rest of the code, Docker can cache the dependency installation layer. This means if only source code changes, Docker reuses the cached `node_modules` layer, significantly speeding up builds.
4. **Build process**: `npm run build` compiles React into static HTML, CSS, and JavaScript files in the `build/` directory.

Why use ARG and ENV together?

React applications read environment variables at **build time**, not runtime. When you run `npm run build`, React's build process embeds environment variable values directly into the compiled JavaScript files. This means:

- **ARG**: Receives values from the build command (e.g., `docker build --build-arg REACT_APP_BACKEND_URL=...`).
- **ENV**: Makes those values available as environment variables during the build process so React can access them.
- **Important**: You cannot use ECS task definition environment variables for React frontends because the values are already baked into the JavaScript files at build time. You must pass them as build arguments.

Why do I need nginx? Why can't I serve the React application directly with Node.js?

After running `npm run build`, React becomes a collection of **static files** (HTML, CSS, JavaScript). These files don't need Node.js to run - they're just files that need to be served by a web server.

Why nginx specifically?

- **Performance**: nginx is highly optimized for serving static content and can handle thousands of concurrent connections efficiently.
- **Size**: The nginx:alpine image is much smaller than keeping Node.js in the production image.
- **Features**: nginx provides features like gzip compression, caching headers, and reverse proxy capabilities if needed later.
- **Industry standard**: nginx is widely used for serving static frontend applications in production.


### Understanding the Production Stage

The second stage (`FROM nginx:1.23.3-alpine`) creates the final production image:

1. **Lightweight base**: `nginx:alpine` is a minimal Linux distribution with nginx pre-installed, typically around 5-10 MB.
2. **Selective copying**: `COPY --from=build` copies only the compiled `build/` directory from the build stage, leaving behind Node.js, npm, source code, and all development dependencies.
3. **Nginx configuration**: The custom `nginx.conf` file is copied to configure how nginx serves the static files.

---

## Nginx Configuration

Since I'm using nginx to serve the React application, I need to provide a configuration file that tells nginx how to serve the static files. I created `frontend-react-js/nginx.conf`:

```nginx
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

### Key Configuration Explanations

**`worker_processes 1`**: Sets the number of worker processes. For a single-container deployment, one worker is sufficient. In production with multiple containers behind a load balancer, you might increase this.

**`listen 3000`**: nginx listens on port 3000, matching the port exposed in the Dockerfile and used by the application.

**`root /usr/share/nginx/html`**: This is the standard nginx directory for serving static files. Our compiled React app is copied here from the build stage.

**`try_files $uri $uri/ $uri.html /index.html`**: This is crucial for React Router (client-side routing). When a user navigates to a route like `/messages`, nginx first tries to find a file at that path. If it doesn't exist (which is normal for React Router routes), it falls back to serving `index.html`. This allows React Router to handle the routing on the client side.

> **Why is `try_files` important for React Router?**
>
> React Router uses client-side routing, meaning the routing happens in JavaScript after the page loads. When a user directly accesses `/messages` or refreshes the page, the browser requests that path from the server. Without `try_files`, nginx would return a 404 because there's no actual `/messages` file. By falling back to `index.html`, React loads, and then React Router can handle the routing and display the correct component.

---

## Complete Environment Variable Flow

Understanding how environment variables flow from your local environment to the final Docker image is important:

```
1. docker-compose.prod.yml (or docker build command)
   args:
     REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}
   ↓ (passes value, e.g., "https://api.example.com")
   
2. Dockerfile ARG REACT_APP_BACKEND_URL
   ↓ (receives "https://api.example.com" as build argument)
   
3. Dockerfile ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
   ↓ (sets environment variable to "https://api.example.com")
   
4. npm run build
   ↓ (React build process reads ENV and embeds "https://api.example.com" into compiled JS files)
   
5. Final image contains static files with the value baked in
```

**Important points:**
- The value is **baked into the JavaScript files** during the build step.
- Changing environment variables in ECS task definitions **will not affect** a React frontend - you must rebuild the image with new build arguments.
- This is different from backend applications (like Flask) where environment variables can be set at runtime.

---

## Building and Testing

To build the production image:

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

Or use docker-compose:

```bash
$ docker-compose -f docker-compose.prod.yml build frontend-react-js
```

---
