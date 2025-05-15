# Schema Migration Scripts

The scripts in this folder are a demo on how we could create the schema in Mediaflux and keep updating it.

The files are named in the order of how the are expected to be run:

- 20250429_0001_schema_create.tcl
- 20250429_0002_namespaces_create.tcl
- 20250429_0003_project_create.tcl
- 20250429_0004_add_optional_field.tcl
- 20250429_0005_add_required_field.tcl
- 20250430_0001_populating_required_field.tcl

## How to run these scripts

You can run these files from aTerm by issuing a command as follows:

```
script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/20250429_0001_schema_create.tcl
```

Or you can run them directly from your Mac Terminal with a command as follows:

```
java -Dmf.host=0.0.0.0 -Dmf.port=8888 -Dmf.transport=http -Dmf.domain=system -Dmf.user=manager -Dmf.password=change_me -jar aterm.jar --app exec script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/20250429_0001_schema_create.tcl
```

Make sure to use the correct connection parameters (host, port, transport, domain, user, password) when using this second method.

## 20250429_0001_schema_create.tcl

This file creates a basic schema definition under `tigerdataX:resourceDoc`. Notice that we are creating these examples outside of the existing `tigerdata` definition so that we don't pollute the existing environment.

## 20250429_0002_namespaces_create.tcl

This file the required namespaces and root collections to mimic our production environment. The code is smart enough to only create them if they are not already there.

This is not technically about the schema, it just makes sure the right namespaces and collections are on the Mediaflux instance before we create any sample data.

## 20250429_0003_project_create.tcl

This script creates a project (i.e. a collection asset) and sets values defined in our metadata schema (the one we defined our first script).

## 20250429_0004_add_optional_field.tcl

This script adds an _optional_ field to the original schema definition.

After this script you could validate the existing project and it will still be valid since the new field is an optional field:

```
asset.meta.validate :id xxxx
```

Make sure to replace `xxxx` with the actual ID of the project that you created.

You'll now it is valid if the command returns nothing.

## 20250429_0005_add_required_field.tcl

This script adds a _required_ field to our schema definition.

After running this script you could validate the existing project and Mediaflux should report the missing data:

```
asset.meta.validate :id xxxx

    :invalid -id "1076" -version "1" -nb "1" "XPath tigerdataX:resourceDoc/resource[resourceClass=Project, resourceID=10.34770/az09-0011, resourceIDType=DOI]
    is invalid: missing element 'newRequiredField'"
```

## Populating required fields

If a new required field with no default value is added to the schema we can set its value with a command as follows:

```
asset.meta.value.set :id 1080 :value -xpath tigerdataX:resourceDoc/resource/newRequiredField -create true "new required value"
```

NOTE: The `-create true` parameter is very important because otherwise `asset.meta.value.set` will refuse to set a value for field that is not already on the document.

The example in the script `20250430_0001_populating_required_field.tcl` shows an example updating all the fields in a document.

After setting the value you can validate the document again with `asset.meta.validate :id xxxx` and it should report no errors:

## Viewing schema versions

You can view the different versions of the schema definition we created with the following command:

```
asset.doc.type.versions :type tigerdataX:resourceDoc
```

and you can also inspect the actual definitions of previous versions via the following command:

```
asset.doc.type.describe :type tigerdataX:resourceDoc -version 3
```
