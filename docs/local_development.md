# Local Development with MediaFlux

Instructions to download MediaFlux as a Docker container and run it locally.

## Prerequisites

* Docker: Make sure Docker is installed and running locally.


## If you have a previous Docker image

Stop the current Docker container and remove both the container and the image used to create it:

```
docker stop mediaflux
docker rm mediaflux
docker rmi princeton_dev:23.08.25
```

## Load the new Docker image

1. Download the latest MediaFlux Docker image from `td-meta.princeton.edu`. This is an internal server and you need to be on the VPN to access it, notice that you'll need to pass your `netid` in the following command and enter your password when prompted:

```
scp your-net-id@td-meta1.princeton.edu:/home/common/princeton_dev_image_v3.tar .
```

1. Load the tar file as a Docker image:

```
docker load -i princeton_dev_image_v3.tar
```

You can view the loaded image via `docker images`:

```
docker images

  # REPOSITORY           TAG                    IMAGE ID       CREATED         SIZE
  # <none>               <none>                 85b0eb016889   3 days ago      1.4GB
  # ...other images...
```

1. Set the `repository` and `tag` values of your local image (notice that the `IMAGE ID` might be different in your local installation)

```
docker image tag 85b0eb016889 princeton_dev:latest
```

1. Now that we have the loaded the image we can _create a container_ with it (notice we name it "mediaflux")

```
docker create --name mediaflux --publish 0.0.0.0:8888:8888 princeton_dev:latest
```

You may need to add ` --mac-address 02:42:ac:11:00:02` before princeton_dev if mediaflux does not start

1. From now on when you need _start this container_ you can use:

```
$ docker start mediaflux
```

6. Once the container is running you can access it at the default endpoints:

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

## Test Projects and Assets

There are a few ways to generate test projects and test assets.  The simplest is to run the rake task `projects:create_small_project`.  For example `rake projects:create_small_project\[cac9,mytest]` will create a project for the user `cac9` under the prefix mytest and create a random amount of assets underneath.

You can also utilize the TestAssetGenerator in the rails console to add assets to an existing project.  For example the following script grabs the first User in the system and the last Project in the system.  It then saves the project to mediaflux and then generates a hierarchy of assets under the project.

```
rails c
  user = User.first
  project = Project.last
  id = ProjectMediaflux.create!(project:, session_id: user.mediaflux_session, xml_namespace: "tigerdata")
  project.mediaflux_id = id
  project.save!
  gen = TestAssetGenerator.new(project_id: project.id,user:, levels: 2, directory_per_level: 2,file_count_per_directory: 20)
  gen.generate
```

You can also utilize `Mediaflux::Http::TestAssetCreateRequest` to generate some assets in an existing collection under a project

```
rails c
  parent_id = 1234 # collection id from mediaflux
  gen = Mediaflux::Http::TestAssetCreateRequest.new(session_token: User.first.mediaflux_session, parent_id:, count: 5, pattern: "test_asset_" )
  gen.resolve
```

## Internal documentation

All notes below are internal and cannot be accessed outside of the PUL IT group.

* [Training notes](https://drive.google.com/drive/folders/1kG6oJBnGqOUdM2cHKPxCOC9fBmAJ7iDo)
* [Hector's training notes](https://drive.google.com/drive/folders/1HGPp43OcGikdZmr3Wd4tgdpY6m1y_PCx)
* [Recordings](https://drive.google.com/drive/folders/19EGm7s7UxOMCCdRRXSscUIkya_gF9Zgs)
