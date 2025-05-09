# Create a namespace and the "root" document type via a TCL script.
#
# You can run this script form aTerm:
#
#   script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/schema_v08_create.tcl
#
# Or directly from the Terminal:
#   java -Dmf.host=0.0.0.0 -Dmf.port=8888 -Dmf.transport=http -Dmf.domain=system -Dmf.user=manager -Dmf.password=change_me -jar aterm.jar --app exec script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/schema_v08_create.tcl
#

# Define where our document type will be located (e.g. tigerdataX:resourceDoc)
# We are not using "tigerdata:project" so that we don't pollute the existing schema in our Mediaflux instances.
set namespace "tigerdataX"
set rootDoc "resourceDoc"
set schemaVersion "v0.8"

# Create the namespace for the metadata definition
asset.doc.namespace.update :create true :namespace $namespace

# Define "resource" as per the proof of concept schema
# indicated in https://github.com/pulibrary/tigerdata_metadata_schema/blob/main/schemas/standard/TigerData_StandardMetadataSchema_v0.8.xsd
#
# Notice that we are using $rootDoc as our document type and "resource" as an element of it because
# MediaFlux does not allow attributes as part of the document type, attributes are allowed as part
# of elements.
#
asset.doc.type.update :create true :description "testing doc definition via a TCL script" :type $namespace:$rootDoc :definition < \
    :element -name resource -type document < \
        :attribute -name resourceClass -type string \
        :attribute -name resourceID -type string \
        :attribute -name resourceIDType -type string  \
        :element -name projectID -type string -min-occurs 1 -max-occurs 1 < \
            :attribute -name projectIDType -type string \
        > \
        :element -name title -type string -min-occurs 1 -max-occurs 1 \
        :element -name projectProvenance -type document -min-occurs 1 -max-occurs 1 < \
            :element -name schemaVersion -min-occurs 1 -max-occurs 1 -type string < :value $schemaVersion -as default > \
        > \
    > \
>
