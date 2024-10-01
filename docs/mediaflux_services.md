# Custom Services in Mediaflux

Mediaflux provides the concept of "custom services" that are custom TCL scripts registered within the service and can be executed at a later point. Similar to running a script with the process described on [mediaflux_script_access.md](https://github.com/pulibrary/tigerdata-app/blob/main/docs/mediaflux_script_access.md) but services have some extra properties.

One of the extra properties of a service is that it can be registered to run as a specific user, which from what I understand, can be different from the user that makes the call to run the service.

## Declaring a new service

Below is an example of how to create a very simple service, it only logs a string to the `hello-service` log, and it's defined in-line (i.e. no external TCL file is used):

```
system.service.add :execute "server.log :app hello-service :event info :msg hello-from-service" :name hello-service :access ACCESS :execute-as < :domain system :user manager >
```

Notice that the service includes the `execute-as` parameter and in this case it was set to `system:manager`.

You can check the service was registered as follows:

```
system.service.list :type declared

# output will include
#
# :service -type "declared" "hello-service"
#
```

And you can view the details of the service with the following command:

```
system.service.describe :service hello-service

# output will include
#
# :service -name "hello-service" -type "declared" -licenced "false"
# :execute "local"
# :script "server.log :app filelist :event info :msg hello-from-service"
# :access "ACCESS"
# :execute-as
#    :domain "system"
#    :user "manager"
# :can-abort "false"
#
```

## Executing the service

You can run the service as follows:

```
service.execute :service -name hello-service

# output will include
#
# :uuid "9047"
# :reply -service "hello-service"
#   :response
#
```

After this the log file (/usr/local/mediaflux/volatile/logs/hello-service.1.log) will include a new entry with the text "hello-from-service".


## Executing the service from a different user

Before we test that we can run this service while logged in as a different user we will give access to the `hello-service` script to the scripter role `pu-lib:scripter` that we defined in [mediaflux_script_access.md](https://github.com/pulibrary/tigerdata-app/blob/main/docs/mediaflux_script_access.md).

```
actor.grant :type role :name pu-lib:scripter :perm < :resource -type service hello-service :access ACCESS >
```

Now that the `pu-lib:scripter` role has access to execute our service **open a new Aterm window** and login as the scripter user: `system:scripter_user`.

Once logged in you can call the service as follows:

```
service.execute :service -name hello-service
```

Unfortunately this will result in an error that indicates that the user `system:scripter_user` does not have access to "MODIFY to service server.log". `server.log` is the call that happens inside our `hello-service.

The full error message is below:

```
error: executing service.execute: [arc.mf.server.Services$ExServiceError]:
call to service 'service.execute' failed:
error executing service [idx=0] hello-service: call to service 'hello-service' failed:
executing script: hello-service [line: 1]:
xarc.mf.server.actor.ExNotAuthorized: user 'system:scripter_user' (id=164) not granted MODIFY to service 'server.log'
```
