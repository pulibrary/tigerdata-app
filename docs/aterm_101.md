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
MediaFlux uses the concept of _namespaces_ and _collection assets_ to organize and the entire list of assets stored on a server. Each of this concepts provides different features and you need both to properly organize your data.

### Namespaces
Namespaces allows you to segment the list of assets on your server at a very basic level. All assets in MediaFlux belong to one (and only one) namespace. Assets names _must be unique_ within a namespace. You can apply Access Control Lists (ACL) to namespaces.

To create a namespace you can use a command as follows:

```
> asset.namespace.create :namespace test01
```

you can use the `asset.namespace.list` to get list of existing namespaces:

```
> asset.namespace.list
    :namespace -path "/"
        :namespace -id "1067" -leaf "true" -acl "false" "hector01"
        :namespace -id "1075" -leaf "false" -acl "false" "td-demo-001"

> asset.namespace.list :namespace /td-demo-001
    :namespace -path "/td-demo-001"
        :namespace -id "1079" -leaf "true" -acl "false" "pppl"
        :namespace -id "1081" -leaf "false" -acl "false" "pul"
        :namespace -id "1077" -leaf "false" -acl "false" "rc"
```

and `asset.namespace.describe` to get detailed information about the namespace, like the store associated with it and it ACL.

Below is an example on how to perform a search and limit to only the assets within the `/td-demo-001` namespace:

```
> asset.query :namespace /td-demo-001
```

**Warning:** Namespaces are labeled "collections" in the Media Flux desktop, but keep in mind that "collection assets" are completelly different concept.

### Collection Assets
Collection Assets are assets that have particular properties to organize other assets, i.e. they act as "collections of assets". Collection assets allow you to have more than one file with the same name. You can index the content of a collection asset which makes them a great option to narrow down scope during searches (particularly since you cannot create indexes on namespaces). You can also apply metadata to collection assets.

Whereas an asset must belong to one and only one namespace, an asset can belong to more than one collection asset.

To create a collection asset we use the same command to create an asset but we give it a few extra arguments. The following command creates a collection asset "test01_collection" inside the "/test01" namespace.

```
> asset.create :namespace /test01 :name test01_collection :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true
    :id "1093"
```

Notice the `:collection true` argument along with the parameters `-unique-name-index`, `-contained-asset-index`, and `-cascade-contained-asset-index` in the previous command.

Once we have a collection asset we can _add assets_ to it by setting the `pid` parameter when we create the asset. It is possible to pass the actual `id` of the collection asset (i.e. `1093` in the previous example) as shown below:

```
> asset.create :pid 1093 :name file2.txt :description "this is the description"
```

or you can pass the `path` of the collection asset as the `pid` as shown here:

```
> asset.create :pid path=/test01/test01_collection :name file3.txt :description "this is the description"
    :id "1096"
```

**Warning:** by default the MediaFlux Desktop does not show assets inside a collection asset as nested objects in the tree, instead it shows them at the same level. You can validate that the assets are indeed inside the collection by clicking on the asset and looking at its properties. If you have admin rights to the MediaFlux server (e.g. if you are running on a local Docker container) you can grant access to your user to the feature that fixes this via `actor.grant :type user :name system:manager :role -type role desktop-experimental`. You'll need to close the Asset Finder in the desktop and re-opened for the change to take effect.

Like with namespaces, it is possible to use collection assets to reduce the scope of searches. We do this by specifing a "root collection" during a search, this limits the search to only assets within a given collection. Below is an example on how to perform a search and limit to only assets within a given root collection asset with id `1093`:

```
> asset.query :collection 1093
    :id -version "1" "1095"
    :id -version "1" "1096"
```

## Asset Metadata
MediaFlux allows you to declare custom metadata fields for your assets. The definition for this kind of metadata is stored in what MediaFlux class "namespace for documents" and they are managed via the `asset.doc.namespace` commands (notice that these namespaces are _not_ the same as the asset namespaces that we saw before with the `asset.namespace` commands).

Namespaces for documents (`asset.doc`) contain "document types" and these document types in turn contain "elements" (aka field definitions).

To create a new namespace for document you use the following command:

```
> asset.doc.namespace.create :namespace sandbox_meta :description "the metadata definition for our sandbox"
```

The syntax to create an empty document type is as follows:

```
> asset.doc.type.update :create true :description "empty doc type" :type sandbox_meta:empty_doc :definition <  >
```

To create a document type with specific elements you need to pass the definition for each of the elements in the command. The following command will create a new document type called `sandbox_meta:project` with three fields inside of it:

* name (string)
* sponsor (string)
* max_gb (integer):

```
> asset.doc.type.update :create true :description "sandbox metadata" :type sandbox_meta:project :definition < :element -name name -type string :element -name sponsor -type string :element -name max_gb -type integer >
```

Once we have defined our document type and its elements (fields) we can set the values for these fields on our assets. For example, to set the values in our `/sandbox_ns/rdss_collection` we could use the following command:

```
> asset.set :id path=/sandbox_ns/rdss_collection :meta < :sandbox_meta:project < :name "RDSS test project" :sponsor "Library" :max_gb 100 > >
```

and we can review this information via the `asset.get` command:


```
> asset.get :id path=/sandbox_ns/rdss_collection


:asset -id "1101" -version "3" -collection "true" -vid "1534"
        :type "content/unknown"
        :namespace -id "1093" "/sandbox_ns"
        :path "/sandbox_ns/rdss_collection"
        :name "rdss_collection"
        ...
         :meta -stime "1534"
            :sandbox_meta:project -xmlns:sandbox_meta "sandbox_meta" -id "2"
                :name "RDSS test project"
                :sponsor "Library"
                :max_gb "100"
```


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

