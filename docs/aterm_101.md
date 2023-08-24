# Aterm
Aterm is the MediaFlux's command line. This is a Java application that you run from your terminal and it allows you to execute commands against a MediaFlux server. You can query for information about assets, create new assets, and update their metadata and content.

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


### Bash-like commands
Aterm supports a few Bash-like commands that you can use as shortcuts, for example:

```
> ls
> pwd
> cd /name-of-namespace
```


## Assets
MediaFlux stores files as assets. An asset contains metadata and _optionally_ content. The metadata and the content are versioned independently.

Internally, assets are records in the database that MediaFlux uses store metadata and run queries against.

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

We can _update the metadata_ of the files with the `asset.set` command, for example the following command will rename a file and give it a description:

```
>  asset.set :id 1083 :name "small.txt" :description "this is a small file"
    :version -id "1083" -stime "1415" -changed-or-created "true" "3"

> asset.get :id 1083
    :asset -id "1083" -version "4" -vid "1416"
        :type "content/unknown"
        :namespace -id "1067" "/hector01"
        :path "/hector01/small.txt"
        :name -ext "txt" "small.txt"
        :description "this is a small file"
        ...
```


### Asset content
It is possible to _set the content_ of an asset via Aterm and this can be useful for testing purposes.

For example to upload the content of a local file on our machine to an existing asset (with id `1082`) we could use the following command:

```
> asset.set :id 1082 :in file:/full/path/to/file.txt
    :version -id "1082" -stime "1414" -changed-or-created "true" "2"

```

In practice the content of files is better updated via the `asset.import` command which allows to import files by reference and set configure what actions should performed on the uploaded files, for example whether we want to analyze the file (i.e. extract metadata from it) or generate checksums.

```
> asset.import :pid 1005 :url -by reference file:/etc
> asset.import :parent 1005 :url -by reference file:/etc :analyze false :gen-csum false :pgen false
```


### Labels and tags
Tags and Labels are a kind of metadata that we can easily added to assets in MediaFlux. Tags apply to all versions of a given asset whereas labels apply to a specific version. See the help for `asset.tag.add` and `asset.label.type.create` for more information.

TODO: Add examples once we have access to `dictionary.create`, `dictionary.add`, and `asset.tag.add`


## Namespaces and Collection Assets

Namespace
* Assets belong to one (and only one) namespace
* Asset name must be unique within namespace (but keep in mind that name is not required!)
* Namespaces are unfortunately called "collections" in the MediaFlux Desktop, but keep in "collection assets" are a completelly different concept.
* Access Control List (ACL) can be set at the namespace level.
* It is recommended that we have a shallow namespace tree (TODO: need to confirm)


Collection Assets
* A file can belong to one or more collection assets.
*


## Stores

MediaFlux uses the concept of _stores_ to determine where asset content is stored. You can view the configured stores in your system via the `asset.store.list` command:

```
> asset.store.list
    :store -id "1"
        :type "database"
        :name "db"
    :store -id "2"
        :type "file-system"
        :name "data"
    :store -id "3"
        :type "s3"
        :name "ibm-cos-1"
```

You can also use the `asset.store.type.list` to figure out what _type of stores_ are available:

```
> asset.store.type.list
    :type "database"
    :type "dmf-file-system"
    :type "file-system"
    :type "nfs"
    :type "remote"
    :type "s3"
```

There is a default stored configured on each server, in the example below we can see that the default store is "data" and from the output of `asset.store.list` previously we know that this store is of type "file-system":

```
> asset.store.default.get
    :name "data"
```

Once stores are defined it is possible to reference them in Aterm commands. For example the following command will create a copy of the content in store `s3` for all the files in the `/something` namespace.

```
> asset.query :where namespace=/something \
	:action pipe :pipe-nb-threads 5 \
	:service-name asset.content.copy.create < :store s3 >
```

