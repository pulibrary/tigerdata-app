# README
The scripts in this folder show how to create the TigerData metadata schema in Mediaflux and
create a couple of sample projects showing how the values are set.

## Scripts
`001_schema_v08_create.tcl` creates the schema in Mediaflux.

`002_namespaces_create.tcl` makes sure root collection `td-demo-001/dev/tigerdata` and the root namespace `td-demo-001/dev/tigerdataNS` are created in Mediaflux.

`003_project_create.tcl` creates a project in Mediaflux with the minimal set of fields required.


## Running the scripts
You can run these script from Aterm via

```
script.execute :in file:/full/path/to/the/script.tcl
```

or from your Mac terminal via:

```
java -Dmf.host=0.0.0.0 -Dmf.port=8888 -Dmf.transport=http -Dmf.domain=system -Dmf.user=manager -Dmf.password=change_me -jar aterm.jar --app exec script.execute :in file:/full/path/to/the/script.tcl
```

You'll need to be on the same folder as your `aterm.jar` file for this to work.