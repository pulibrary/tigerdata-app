![TigerData logo](https://raw.githubusercontent.com/pulibrary/tigerdata-app/main/app/assets/images/logo-300-200.png)

# tigerdata-app

TigerData is a comprehensive set of data storage and management tools and services that provides storage capacity, reliability, functionality, and performance to meet the needs of a rapidly changing research landscape and to enable new opportunities for leveraging the power of institutional data.

This application provides a front end for users to create and manage projects that live in the TigerData infrastructure.

[![CircleCI](https://circleci.com/gh/pulibrary/tigerdata-app/tree/main.svg?style=svg)](https://circleci.com/gh/pulibrary/tigerdata-app/tree/main)
[![Coverage Status](https://coveralls.io/repos/github/pulibrary/tigerdata-app/badge.svg?branch=main)](https://coveralls.io/github/pulibrary/tigerdata-app?branch=main)

## Documentation

- Auto-built code documentation is available at [https://pulibrary.github.io/tigerdata-app/}](https://pulibrary.github.io/tigerdata-app/)
- Design documents and meeting notes are in [Google Drive](https://drive.google.com/drive/u/1/folders/0AJ7rJ2akICY2Uk9PVA)
- RDSS internal notes are in a [separate directory](https://drive.google.com/drive/u/1/folders/1kG6oJBnGqOUdM2cHKPxCOC9fBmAJ7iDo)
- A set of requirements derived from early sketches is [here](https://docs.google.com/document/d/1U06FBX0qR9iMNiWes5YhP0schcPiLTmFwjHurduSb3A/edit).
- We're writing a ["Missing Manual"](docs/) for the subset of Mediaflux that is used by TigerData.

## Structure

The [conceptual diagrams](https://docs.google.com/presentation/d/14W896a_NZ4Q93OPnBVJjz8eQOytwkr6DFxcZ4Lx5YNI/edit?usp=sharing) showcase the user (i.e. a researcher or SysAdmin) and their typical interactions with the TigerData-rails application. The conceptual designs were created based on the TigerData design framework, and may be subject to change dependent upon any updates to the framework.

### Roles
The system will eventually have many roles.  Please refer to the [docs for a description](https://github.com/pulibrary/tigerdata-app/blob/main/docs/roles.md) of the system roles

## Local development

### Setup

1. Check out code and `cd`
1. Install tool dependencies; If you've worked on other PUL projects they will already be installed.
    1. [Lando](https://docs.lando.dev/getting-started/installation.html)
    1. [asdf](https://asdf-vm.com/guide/getting-started.html#_2-download-asdf)
    1. postgresql (`brew install postgresql`: PostgreSQL runs inside a Docker container, managed by Lando, but the `pg` gem still needs a local PostgreSQL library to install successfully.)
1. Install asdf dependencies with asdf
    1. `asdf plugin add ruby`
    1. `asdf plugin add node`
    1. `asdf plugin add yarn`
    1. `asdf plugin add java`
    1. `asdf install`
    1. ... but because asdf is not a dependency manager, if there are errors, you may need to install other dependencies. For example: `brew install gpg`
1. OR - Install dependencies with brew and chruby
   1. `ruby-install 3.2.3 -- --with-openssl-dir=$(brew --prefix openssl@1.1)`
   2. If you get "error: use of undeclared identifier 'RUBY_FUNCTION_NAME_STRING'" while updating, make sure your Xcode toolks are up to date.
   3. close the terminal window and open a new terminal
   4. `chruby 3.2.3`
   5. `ruby --version`
2. Install language-specific dependencies
    1. `bundle install`
    2. `yarn install`

On a Mac with an M1 chip, `bundle install` may fail. [This suggestion](https://stackoverflow.com/questions/74196882/cannot-install-jekyll-eventmachine-on-m1-mac) helped:
```
gem install eventmachine -v '1.2.7' -- --with-openssl-dir=$(brew --prefix libressl)
brew install pkg-config
bundle install
```

### Starting / stopping services

We use lando to run services required for both test and development environments.

Start and initialize database services with:

`bundle exec rake servers:start`

To stop database services:

`bundle exec rake servers:stop` or `lando stop`

You will also want to run the vite development server:

`bin/vite dev`

### Populate the authorized users table
Authentication and authorization is restricted to a few selected users. Make sure to run the rake task to pre-populate your local database:

```
bundle exec rake load_users:from_registration_list
```

If your name is not on the registration list see steps below under "User Registration List" for instructions on how to add yourself.

#### MediaFlux Server

Documentation for starting the mediaflux server can be found at [doc/local_development](https://github.com/pulibrary/tigerdata-app/blob/main/docs/local_development.md)


##### Authentication

By default, there exists for the MediaFlux deployment a user account with the following credentials:

- domain: `system`
- user: `manager`
- password: `change_me`

Alternatively, one may please use `docker/bin/shell` to create a terminal session within the container and find individual accounts within the file `/setup/config/users.json`.

##### aterm Client

The MediaFlux `aterm` may be accessed using http://0.0.0.0:8888/aterm/

##### Desktop Client

The MediaFlux desktop client may be accessed using http://0.0.0.0:8888/desktop/

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

The MediaFlux service documentation may be accessed using http://0.0.0.0.:8888/mflux/service-docs/


### How to run test suite
- `asdf install`
- `bundle install`
- `yarn install`
- `bundle exec rake servers:start`
- Fast: `bundle exec rspec spec`
- Run in browser: `RUN_IN_BROWSER=true bundle exec rspec spec`
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

## User Registration List
For local development, add yourself as a SuperUser to the TigerData preliminary registration list and follow these instructions:

### Updating User Registration List
To save updates and make changes to appointed users for early testing of the TigerData site:

1. Make the requested changes to the [Google spreadsheet](https://docs.google.com/spreadsheets/d/169lfRTOSe6H66Iu2DK5g-QzqiVsfz5lHFHMaGmwNT7Y/edit#gid=0)
2. Save those updated changes
3. Download the file as a .CSV file
4. Copy the downloaded .CSV file to `data` > `user_registration_list.csv`
5. run SED to remove the ^M from the file `sed -e "s/\r//g" user_registration_list.csv > user_registration_list_production.csv`
6. Open a PR to check the updated file into version control
7. Once that PR is merged, release and deploy the code. This will automatically run the `load_users.rake` rake task.

## Sidekiq

[Sidekiq](https://sidekiq.org/) is used to run backgroud jobs on the server.  The jobs are created by ActiveJob and ActiveMailer.

You can go to the following urls to see the sidekiq dashboard, but because these environments are load balanced, that view will switch back and forth between hosts.
 - https://tigerdata-staging.lib.princeton.edu/sidekiq
 - https://tigerdata-qa.princeton.edu/sidekiq
 - https://tigerdata-app.princeton.edu/sidekiq

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
