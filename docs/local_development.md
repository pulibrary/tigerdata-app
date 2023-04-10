# Local Development with MediaFlux

This README describes the recommended approach to get up and running with MediaFlux for local development on your own machine, using Docker.

## Prerequisites

* Docker 

## Getting started

1. Make sure Docker is installed and running locally.
1. Pull the latest TigerData Docker image from either the vendor or the private Princeton Docker registry.  Information for how to connect and pull this image are located in LastPass.
1. In a terminal, run the following Docker command:
    ```bash 
      docker run --interactive --rm --tty --privileged --init --name mediaflux --publish 0.0.0.0:8888:8888 $DOCKER_IMAGE_REGISTRY/$NAMESPACE/developer-image:latest /bin/bash
    ```
    Where `$DOCKER_IMAGE_REGISTRY` and `$NAMESPACE` are replaced with values found in LastPass in the previous step.
1. Upon running the Docker command, you should see output like the following:
   ```bash 
     WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
     root@123abc:/setup#
   ```
   You are now inside of the Docker container running MediaFlux.
1. Inside the container, run the following command:
   ```bash 
     /usr/bin/env java -jar /usr/local/mediaflux/bin/aserver.jar application.home=/usr/local/mediaflux nogui
   ```
   This will start the MediaFlux service.  Leave the service running in this tab.

1. In a new tab, bash into the container to work on the filesystem as follows:
   ```bash
     docker exec -it $CONTAINER_ID /bin/bash
   ```

1. You can now access MediaFlux in the browser and terminal.  Default local sign-in credentials are available in LastPass.

   Some endpoints where you can work with now include:
     * The Desktop client - http://0.0.0.0:8888/desktop/
     * The aterm client in the browser - http://0.0.0.0:8888/aterm/ 
     * Service documentation - http://0.0.0.0:8888/mflux/service-docs 
     * The thick client for aterm (see instructions below)

## Accessing the thick client

1. Get a copy of `aterm.jar` to run locally.  You can do this by going to [http://0.0.0.0:8888/mflux/aterm.jar](http://0.0.0.0:8888/mflux/aterm.jar) while the container is running, or by copying the aterm.jar file from the running Docker container as follows:
   ```bash 
     docker cp $CONTAINER_ID:/usr/local/mediaflux/bin/aterm.jar ~/aterm.jar
   ```
1. Go to the directory containing `aterm.jar` and start the client:
   ```bash 
     java -Xmx4g -Djava.net.preferIPv4Stack=true -jar ~/aterm.jar &
   ```
1. At the login screen, change "server" to `0.0.0.0` and "port" to `8888`.  Use the domain, user, and password information in LastPass to log in.

