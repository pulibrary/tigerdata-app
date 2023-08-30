# Local Development with MediaFlux

Instructions to download MediaFlux as a Docker container and run it locally.

## Prerequisites

* Docker

## Getting started

1. Make sure Docker is installed and running locally.

2. Download the latest MediaFlux Docker image from `td-meta.princeton.edu`. This is an internal server and you need to be on the VPN to access it, notice that you'll need to pass your `netid` in the following command and enter your password when prompted:

```
$ scp your-net-id@td-meta1.princeton.edu:/home/common/princeton_dev.23.08.25.tar.bz2 .
```

3. Unzip the downloaded file, this process takes a few minutes:

```
$ bunzip2 princeton_dev.23.08.25.tar.bz2
```

4. Load the tar file as a Docker image:

```
$ docker load -i princeton_dev.23.08.25.tar
```

You can view the loaded image via `docker images`:

```
$ docker images
REPOSITORY           TAG                    IMAGE ID       CREATED         SIZE
princeton_dev        23.08.25               311dab7822dd   3 days ago      1.35GB
...other images...
```

1. Now that we have the loaded the image we can _create a container_ with it (notice we name it "mediaflux")

```
$ docker create --name mediaflux --publish 0.0.0.0:8888:8888 princeton_dev:23.08.25
```

6. From now on when you need _start this container_ you can use:

```
$ docker start mediaflux
```

7. Once the container is running you can access it at the default endpoints:

  * The Desktop client - http://0.0.0.0:8888/desktop/
  * The Aterm client in the browser - http://0.0.0.0:8888/aterm/
  * Service documentation - http://0.0.0.0:8888/mflux/service-docs
  * The thick client for aterm (see instructions below)


8. You can stop the container in the Docker dashboard or via

```
$ docker stop mediaflux
```

and restart it via and it will preserve your changes (e.g. the assets that you added)

```
$ docker start mediaflux
```


## SSHing into the container

Once the container is running we can SSH into it, this is useful to look at the logs of the running MediaFlux server:

```
$ docker exec -it mediaflux /bin/bash
root@12345:/setup#
```

The logs are found under the `/usr/local/mediaflux/volatile/logs` folder.

If for some reason you need to _manually_ launch MediaFlux server you can use a command as follows:

```
$ root@12345:/setup# /usr/bin/env java -jar /usr/local/mediaflux/bin/aserver.jar application.home=/usr/local/mediaflux nogui
```

## Accessing the thick client (Aterm)

1. Get a copy of `aterm.jar` to run locally.  While the container is running run the following cURL command to download it:

```
$ curl -OL http://0.0.0.0:8888/mflux/aterm.jar
```

2. Run it

```
$ java -jar aterm.jar
```

3. At the login screen, change "server" to `0.0.0.0` and "port" to `8888`.  Use the default domain, user, and password information.

See [Aterm for beginners](aterm_101.md) for more information on Aterm.

## Internal documentation

All notes below are internal and cannot be accessed outside of the PUL IT group.

* [Training notes](https://drive.google.com/drive/folders/1kG6oJBnGqOUdM2cHKPxCOC9fBmAJ7iDo)
* [Hector's training notes](https://drive.google.com/drive/folders/1HGPp43OcGikdZmr3Wd4tgdpY6m1y_PCx)
* [Recordings](https://drive.google.com/drive/folders/19EGm7s7UxOMCCdRRXSscUIkya_gF9Zgs)
