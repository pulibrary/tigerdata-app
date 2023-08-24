# Aterm
Aterm is the MediaFlux' command line. This is a Java application that you run from your terminal and it allows you to execute commands against a MediaFlux server. You can query for information about assets, create new assets, and update their metadata and content.

In a standard MediaFlux installation you can download Aterm directly as follows:

```
$ curl -OL http://mediaflux-server-url/mflux/aterm.jar
```

Once you have downloaded the `aterm.jar` file to you run it from your terminal as follows:

```
$ java -jar aterm.jar
```

You'll need to enter your credentials for the server that you want to connect to.

The credentials for the development server are under LastPass. Note that you must be on the VPN to connect to the development server.


## Basic commands
Once connected to a server, you can get the version of MediaFlux that is running on the server with a command like this:

```
> server.version
    :ant-version "Apache Ant 1.10.7"
    :binary "aserver"
    :build-time "21-Jul-2023 20:30:16 AEST"
    :built-by "Arcitecta. Pty. Ltd."
    :created-by "1.8.0_292-b10 (Azul Systems, Inc.)"
    :manifest-version "1.0"
    :target-jvm "1.8"
    :vendor "Arcitecta Pty. Ltd."
    :version "4.15.002"
```

You can get a list of files (assets in MediaFlux lingo) in your current namespace with the following command:
```
> asset.query
    :id -version "1" "1"
    :id -version "1" "2"
    :id -version "1" "3"
    :id -version "1" "4"
    :id -version "1" "5"
    ...
```

By default Aterm will only return the ids of the assets, but you can request more information via the `:action` parameter, for example:

```
> asset.query :action get-name
    :name -id "1" -version "1" "index.html"
    :name -id "2" -version "1" "Arcitecta.css"
    :name -id "3" -version "1" "Arcitecta Dots Grey.png"
    :name -id "4" -version "1" "mf-www-plugin.jar"
    :name -id "5" -version "1" "_portal.html"
    :name -id "6" -version "1" "qr.html"
    :name -id "7" -version "1" "_destroy.phtm"
    :name -id "8" -version "1" "_help.phtm"
    :name -id "9" -version "1" "_logon.phtm"
    ...
```

### Auto-complete
Aterm supports auto-complete as you type commands, this is userful to figure our what commands are available to you and what parameters you can pass to each command. To trigger auto-complete use the `TAB` in your keyboard.

For example, to view the list of command under the `asset` category you could type:

```
> asset.<TAB>
asset.accumulator.  asset.acl.  ...
asset.query.  asset.reanalyze ...
```

and then to view the parameters that you could pass to the `asset.query` command you could type:

```
> asset.query :<TAB>
 :action [enumeration optional(1)]
         Action to apply to query. Defaults to 'get-id'
         ...
    :as [enumeration optional(1)]
         ...
    :cache [enumeration optional(1)]
         ...
    :check-if-image [boolean optional(1)]
         ...
```


### Changing your prompt
The default prompt in Aterm is the `>` character, you can change it via the `display` command:

```
> help display
> display prompt "td-meta1 > "
> display save
```


### Bash like commands
Aterm supports a few Bash-like commands that you can use as shortcuts, for example:

```
> ls
> pwd
> cd /name-of-namespace
```


## Assets
MediaFlux stores files as assets. An asset contains metadata and _optionally_ content. The metadta and the content are versioned independently.

Internally, assets are records in the XODB database that MediaFlux uses store metadata and run queries against.

To create an asset we can use a command as follows:

```
> asset.create :name file01
    :id "1082"
```

This created an asset that has only metadata (i.e. there is no content associated with it). We'll see how to upload content later on.

Once an asset has been created we can fetch its metadata as follows:

```
> asset.get :id 1082
    :asset -id "1082" -version "1" -vid "1412"
        :type "content/unknown"
        :namespace -id "1" "/"
        ...
        :path "/file1"
        :name "file1"
        :meta -stime "1412"
            :mf-revision-history -id "1"
                :user -id "3433"
                    :authority -protocol "ldap" "princeton"
                    :domain "princeton"
                    :name "hc8719"
                :type "create"
```

We can run queries against assets via the `asset.query` command:

```
> asset.query :where "name starts with 'file'"
    :id -version "1" "1082"
    :id -version "1" "1083"
```

## Namespaces and Collections


