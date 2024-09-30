# Access Permissions for Mediaflux script

In Mediaflux the fact that a user has rights to execute scripts (e.g. `asset.script.execute`) does not grant the user the right to execute all the commands within the script. For example if the script calls `asset.query` the user must also have access to `asset.query` for the script to execute sucessfully.

## Setting up the example
This page provides a working example to validate confirm this and can be used a as starting point for futher experiments with user rights, for example when we test with "custom service" calls which are similar in concept to the example on this page.

The *script* used in this page as an example is assumed to be a TCL script already loaded in Mediaflux and marked for execution. You setup this script on your local copy of Mediaflu with the following Rake task:

```
bundle exec rake projects:script_upload[your-netid]
```

The previous command is hard-coded to upload a TCL script called `fileList.tcl` to `/system/scripts` in Mediaflux. You can run this script as the `tigerdataapp` user via a Rake task as follows:

```
bundle exec rake projects:script_file_list[your-netid,/path/to/collection]
```

You can view the contents of the `fileList.tcl` script on GitHub at https://github.com/pulibrary/tigerdata-app/blob/main/lib/assets/fileList.tcl (or by downloading the file directly from `/system/scripts` in your local Mediaflux)

Once the script has been uploaded and verified that it can run with the `tigerdataapp` user then we can follow the steps on this page to see what permissions it needs to run.


## Creating a bare-bones role for testing

Run the following commands from Aterm to create a new `pu-lib:scripter` role

```
authorization.role.namespace.create :ifexists ignore :namespace pu-lib :description "Princeton Library Personnel"
authorization.role.create :ifexists ignore :role pu-lib:scripter :description "Script runner"
authorization.role.list
```

Then you can run the following steps to give this new role minimal access:

```
actor.grant :type role :name pu-lib:scripter :perm < :resource -type service user.self.settings.get :access ACCESS >
actor.grant :type role :name pu-lib:scripter :perm < :resource -type service asset.script.execute :access ACCESS >
actor.grant :type role :name pu-lib:scripter :perm < :resource -type service server.log :access MODIFY >
```

In this case we are giving the user access to fetch their own settings (`user.self.settings.get`), execute scripts (`asset.script.execute`), and to log entries on the server log (`server.log`).

This role does not have access to execute `asset.query`.


## Creating a new user and assign it to our new role

Run the following commands to create a new user (`system:scripter_user`) and assign this user *only* to our `pu-lib:scripter` role. Notice that we are *not* assignig the new user to the `standard-user` role:

```
authentication.user.create :ifexists ignore :domain system :user scripter_user :description "user that runs scripts"  :add-role pu-lib:scripter :password ThisIsATest1
```

You can view the permissions that this user gets from the roles assigned to them with the following command:

```
authentication.user.describe :domain system :user scripter_user :permissions -levels 20 true
```

For this particular case the output will include something as follows:

```
...blah blah blah
:role -id "156" -type "role" -name "pu-lib:scripter"
            :perm
                :access "ACCESS"
                :resource -type "service" "asset.script.execute"
            :perm
                :access "MODIFY"
                :resource -type "service" "server.log"
            :perm
                :access "ACCESS"
                :resource -type "service" "user.self.settings.get"
```

## Testing our new user
Login from a **separate** Aterm window as our new user:
* Domain: `system`
* User: `scripter_user`
* Password: `ThisIsATest1`

From this new ATerm window execute the TCL script that we uploaded at the beginning:


```
asset.script.execute :id path=/system/scripts/fileList.tcl :arg -name path /path/to/collection
```

ATerm will report an error indicating that

```
user 'system:scripter_user' has not been granted ACCESS to service 'asset.query'
```

where `asset.query` is the command inside the `fileList.tcl` script.


What this shows is that the `system:scripter_user` has access to `asset.script.execute` script but because they don't have access to `asset.query` the script cannot complete successfully. Remember that [the script](https://github.com/pulibrary/tigerdata-app/blob/main/lib/assets/fileList.tcl), internally, calls `asset.query`.

Because the user has has access to `server.log` we can even look at the log on the Mediaflux server and see that it logged that it was indeed executing:

```
$ cat /usr/local/mediaflux/volatile/logs/filelist.1.log

# output will include something along the lines of
# [281 76649: Network Connection: http [port=8888]],version=4.16.032,filelist,30-Sep-2024
# 20:34:44.081:INFO:[user, id=157] system:scripter_user: File list for /path/to/collection
```

If we were to grant access to our user rights to `asset.query` then the script runs:

```
actor.grant :type role :name pu-lib:scripter :perm < :resource -type service asset.query :access ACCESS >
```


## Destroying our test user and role

If you want to start from scratch and test with different permissions you might want to delete the existing user and role with the following commands:

```
authentication.user.destroy :domain system :user scripter_user
authorization.role.destroy :role pu-lib:scripter
```
