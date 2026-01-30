## Dockerize the Frontend Framework

It all starts with creating a `Dockerfile` (Yes, without extension) under the root of the `frontend-react-js` folder.

Add the following contents in `Dockerfile`:
```
FROM node:16.18

WORKDIR /frontend-react-js

COPY package.json .

RUN npm install

COPY . .

ENV PORT=3000

EXPOSE 3000

CMD ["npm", "start"]
```

Let's understand what each command does:

`FROM` - Every Dockerfile beings with `FROM` command. It defines the base image your app is built on. The base image contains the necessary library, runtime, dependinces etc. Since we’re using a React app, we use the official Node.js image node:16.18 as the base.

`WORKDIR` - Use this command to set the default directory inside container terminal. For example, when you log into ubuntu machine, and fireup the terminal, the prompt is at /home/{name}. Likewise when you login to container, the prompt is at /backend-flask. Also the subsiquent steps like copying files, running commands all happend from this directory.

`COPY` - Use this command to copy local files into container's `WORKDIR`.
You might get a question like why are copying only `package.json`? why not complete frontend-react-js folder? Reason being when building a Docker image, it's a good practice to copy only what's necessary at each step to take advantage of Docker's layer caching.To load the python libraries all we need is `package.json`. So by copying only package.json and running npm install, Docker caches this layer. If you later change your application code but not package.json, Docker reuses the cached layer instead of reinstalling dependencies, making builds faster. 

By copying `package.json` separately, we ensure dependency installation is cached independently.

`RUN` - Use this command to run commands during the image build process. It is used for setup stuff to install packages, configure the system, or prepare the application environment. So basically when you run `docker build` command, the RUN command contents are loaded.

`ENV` - You can set any environment variables required for your application

`EXPOSE` - It is for documenation purpose only to let know users that app will be served on the mentioned port.

`CMD` - Use this command what to run when a container is started. So basically when you run `docker run` command, the CMD command contents are loaded.


To see container in action, you must follow two steps:

Build the docker:
```
$ sudo docker build -t frontend ./frontend-react-js
```
here -t means tag. tags have `image-name:{image_version}` format.
If you don't mention the tag, then it defaults to latest i.e `image-name:latest`

Run the docker:
```
$ sudo docker run -p 3000:3000 -d --name frontend frontend:latest
```

-p = publish port. It has {host_port}:{container_port} format.
-d = run the container in detatched node
--name = name of the container. If you don't specify it, Docker will assign a random name.



