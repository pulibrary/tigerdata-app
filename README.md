![TigerData logo](https://raw.githubusercontent.com/pulibrary/tigerdata-app/main/app/assets/images/logo-300-200.png)

# tigerdata-app

TigerData is a comprehensive set of data storage and management tools and services that provides storage capacity, reliability, functionality, and performance to meet the needs of a rapidly changing research landscape and to enable new opportunities for leveraging the power of institutional data.

This application provides a front end for users to create and manage projects that live in the TigerData infrastructure.

[![CircleCI](https://circleci.com/gh/pulibrary/tigerdata-app/tree/main.svg?style=svg)](https://circleci.com/gh/pulibrary/tigerdata-app/tree/main)
[![Coverage Status](https://coveralls.io/repos/github/pulibrary/tigerdata-app/badge.svg?branch=main)](https://coveralls.io/github/pulibrary/tigerdata-app?branch=main)

## Documentation

- Auto-built code documentation is available at [https://pulibrary.github.io/tigerdata-app/](https://pulibrary.github.io/tigerdata-app/)
- Design documents and meeting notes are in [Google Drive](https://drive.google.com/drive/u/1/folders/0AJ7rJ2akICY2Uk9PVA)
- RDSS internal notes are in a [separate directory](https://drive.google.com/drive/u/1/folders/1kG6oJBnGqOUdM2cHKPxCOC9fBmAJ7iDo)
- A set of requirements derived from early sketches is [here](https://docs.google.com/document/d/1U06FBX0qR9iMNiWes5YhP0schcPiLTmFwjHurduSb3A/edit).
- We're writing a ["Missing Manual"](docs/) for the subset of Mediaflux that is used by TigerData.

## Structure

The [conceptual diagrams](https://docs.google.com/presentation/d/14W896a_NZ4Q93OPnBVJjz8eQOytwkr6DFxcZ4Lx5YNI/edit?usp=sharing) showcase the user (i.e. a researcher or SysAdmin) and their typical interactions with the TigerData-rails application. The conceptual designs were created based on the TigerData design framework, and may be subject to change dependent upon any updates to the framework.

### Roles

The system will eventually have many roles.  Please refer to the [docs for a description](https://github.com/pulibrary/tigerdata-app/blob/main/docs/roles.md) of the system roles

## Local development

### Setup (Devbox)

1. Install devbox (./bin/first-time-setup.sh)
1. `devbox shell`
1. `devbox run setup`

### Starting / stopping services

We use lando to run services required for both test and development environments.

Start and initialize database and mediaflux services with:

`bundle exec rake servers:start`

To stop database and mediaflux services:

`bundle exec rake servers:stop`

You will also want to run the vite development server:

`bin/vite dev`

### Creating users for development and testing

Users can be added one-by-one via an LDAP lookup of their net ID with the following rake task (example argument):

`bundle exec rake load_users:load_single_user\["abc123"]`

***In the non-production environments only***, elevate an existing user to developer with the following rake task (example argument):

`bundle exec rake user_roles:add_developer\["abc123"]`

Similarly, ***in the non-production environments only***, you can remove developer from a user with the following rake task (example argument):

`bundle exec rake user_roles:remove_developer\["abc123"]`

#### MediaFlux Server

You should no longer have to start mediaflux separately. `bundle exec rake servers:start` includes spinning up mediaflux in docker.
Additional documentation for starting the mediaflux server can be found at [doc/local_development](https://github.com/pulibrary/tigerdata-app/blob/main/docs/local_development.md)

##### Authentication

By default, there exists for the MediaFlux deployment a user account with the following credentials:

- domain: `system`
- user: `manager`
- password: `change_me`

Alternatively, one may please use `docker/bin/shell` to create a terminal session within the container and find individual accounts within the file `/setup/config/users.json`.

##### aterm Client

The MediaFlux `aterm` may be accessed using <http://0.0.0.0:8888/aterm/>

##### Desktop Client

The MediaFlux desktop client may be accessed using <http://0.0.0.0:8888/desktop/>

##### Thick Client

One may start and access the Thick Client using the Java Virtual Machine with the following steps:

```bash
$ docker/bin/start
# Within another terminal session, please invoke:
$ docker cp mediaflux:/usr/local/mediaflux/bin/aterm.jar ~/aterm.jar
$ java -Xmx4g -Djava.net.preferIPv4Stack=true -jar ~/aterm.jar
```

###### Configuration Commands

```bash
> server.identity.set :name carolyn
> display font-size 18
> display prompt   "carolyn > "
> display save
```

##### Service Documentation

The MediaFlux service documentation may be accessed using <http://0.0.0.0.:8888/mflux/service-docs/>

### How to run test suite

- `asdf install`
- `bundle install`
- `yarn install`
- `bundle exec rake servers:start`
- Fast: `bundle exec rspec spec`

### How to run system tests

If you want to watch feature tests run for debugging purposes, you can go to
<http://localhost:7900>, use the password `secret`, and run tests like this:

`RUN_IN_BROWSER=true bundle exec rspec spec`

### How to connect to CI while running the tests

- Run connected to CI mediaflux instance: `MFLUX_CI=true MFLUX_CI_PASSWORD="[MFLUX_CI_PASSWORD]" bundle exec rspec spec`
- `MFLUX_CI_PASSWORD` can be found in the tigerdata-config vault

### How to run only integration tests

- To run just the tests that are integration tests, we will need to pass a flag that will only run tests that are tagged as an integration test `bundle exec rspec --tag integration`

### Starting the development server

1. `bundle exec rails s -p 3000`
2. Access application at [http://localhost:3000/](http://localhost:3000/)

## Production and Staging Deployment

Deploy with Capistrano (we are intending to have a deployment mechanism with Ansible Tower, but that is not yet implemented)
```bundle exec cap production deploy```
or
```bundle exec cap staging deploy```

## Load Balancer

To remove a machine from the load balancer you can use the following command:

```
bundle exec cap --hosts=tigerdata-prod1 production application:remove_from_nginx
```

Notice that the name of the machine (`tigerdata-prod1` in the example above) must match with the name of the machine indicated in `config/deploy` for the environment that you are working. When execution of this command is successful you should see a message with the changes made on the server, if you see nothing it is probably because you are not passing the right `hosts`.

You can use `application:serve_from_nginx` to re-add the machine to the load balancer.

## Mail

### Mail on Development

Mailcatcher is a gem that can also be installed locally.  See the [mailcatcher documentation](https://mailcatcher.me/) for how to run it on your machine.

### Mail on Staging and QA

To See mail that has been sent on the Staging and QA servers you can utilize capistrano to open up both mailcatcher consoles in your browser (see below).  Look in your default browser for the consoles

#### staging command

```
cap staging  mailcatcher:console
```

#### qa command

```
cap qa  mailcatcher:console
```

### Mail on Production

Emails on production are sent via [Pony Express](https://github.com/pulibrary/pul-it-handbook/blob/f54dfdc7ada1ff993a721f6edb4aa1707bb3a3a5/services/smtp-mail-server.md).

## Sidekiq

[Sidekiq](https://sidekiq.org/) is used to run backgroud jobs on the server.  The jobs are created by ActiveJob and ActiveMailer.

You can go to the following urls to see the sidekiq dashboard, but because these environments are load balanced, that view will switch back and forth between hosts.

- <https://tigerdata-staging.lib.princeton.edu/sidekiq>
- <https://tigerdata-qa.princeton.edu/sidekiq>
- <https://tigerdata-app.princeton.edu/sidekiq>

Instead, use the capistrano task, which will open an ssh tunnel to all nodes in a tigerdata environment (staging, qa or production), with a tab in your browser for each one.

- `cap staging sidekiq:console`
- `cap qa sidekiq:console`
- `cap production sidekiq:console`

### Workers

Workers must be running on each server in order for mail to be sent and background jobs to be run.
 The sidekiq workers are run on the server via a service, `tiger-data-workers`.  To see the status on the workers on the server run `sudo service tiger-data-workers status`.  You can restart the workers by running `sudo service tiger-data-workers restart`.

## Manually attaching a File Inventory Job

To attach the output of an existing File Inventory Job to a user we can run the rake task `file_inventory:attach_file`.

1. Log into one of the production machines
1. Find the `job_id` of the job that you want to attach the file to. You can do this via the Rails console (for example finding the last job for the user that is having problems)
1. Find the file that you want to attach to the job. Files are under `/mnt/nfs/tigerdata` and each file is named after their `job_id`. Copy this file to a file named after the `job_id` that you will attach it to.
1. Run the rake task giving it the `job_id` and the name of the file that you want to attach to it.

For example if the `job_id` is "xxxx-yyyy-zzzz" you'll run the Rake task as follows:

```
bundle exec rake file_inventory:attach_file[xxxx-yyyy-zzzz,/mnt/nfs/tigerdata/xxxx-yyyy-zzzz.csv]
```

Technically you don't need to copy the source file to a new file named after the `job_id` that you are interested but keeping each file named after the job that they belong keeps things tiddy. Plus since each file will be cleaned up on their own schedule having them separate also prevents the file from dissapearing for one user then it's cleaned up for another user.

## Logging

### Mediaflux

When running mediaflux `locally`, you can find server and start up logs by sshing into the running container with the following commands:

```
docker exec -it mediaflux /bin/bash
cd /opt/mediaflux/volatile/logs/
```

Similarly, you can find mediaflux logs located on a `running server` with the following commands:

```
ssh pulsys@mflux-ci1.lib.princeton.edu
cd /opt/mediaflux/volatile/logs/
```

note: you may need to be a root user to have the permissions necessary to enter the volatile directory and beyond

### CircleCI-Nomad

CircleCI tasks that run in Nomad infrastructure send logs to [Signoz](https://grafana-nomad.lib.princeton.edu/a/grafana-lokiexplore-app/explore/service/circleci-runner-deploy/logs?patterns=%5B%5D&from=now-3h&to=now&var-ds=ffh9d36igqgw0b&var-filters=service_name%7C%3D%7Ccircleci-runner-deploy&var-fields=&var-levels=&var-metadata=&var-patterns=&var-lineFilterV2=&var-lineFilters=&urlColumns=%5B%5D&visualizationType=%22logs%22&displayedFields=%5B%22message%22%5D&var-fieldBy=$__all&var-labelBy=&timezone=browser&var-all-fields=&sortOrder=%22Descending%22&wrapLogMessage=false). Logs related to infrastructure failers, or test failures due to mediaflux errors can be found here.
