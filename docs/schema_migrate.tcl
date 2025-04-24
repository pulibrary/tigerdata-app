# Create a namespace and the "root" document type via a TCL script.
#
# To run this script form aTerm:
#
#   script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema_migrate.tcl

# Define where our document type will be located (e.g. tigerdataX:resourceDoc)
set namespace "tigerdataX"
set rootDoc "resourceDoc"
set schemaVersion "v0.8a"

# Create the namespace
asset.doc.namespace.update :create true :namespace $namespace

# Define "resource" as defined in the TigerData schemaVersion
#
# Notice that we are using $rootDoc as our root and "resource" as an element of it because
# MediaFlux does not allow attributes as part of the type, attributes are allowed as part
# of elements.
#
asset.doc.type.update :create true :description "testing doc definition via a TCL script" :type $namespace:$rootDoc :definition < \
    :element -name resource -type document < \
        :element -name resourceClass -type string -min-occurs 1 -max-occurs 1 \
        :element -name resourceID -type string -min-occurs 1 -max-occurs 1 \
        :element -name resourceIDType -type string -min-occurs 1 -max-occurs 1 \
        :element -name projectID -type string -min-occurs 1 -max-occurs 1 < \
            :attribute -name projectIDType -type string \
        > \
        :element -name title -type string -min-occurs 1 -max-occurs 1 \
        :element -name projectProvenance -type document -min-occurs 1 -max-occurs 1 < \
            :element -name schemaVersion -min-occurs 1 -max-occurs 1 -type string < :value $schemaVersion -as constant > \
        > \
    > \
>

# Versioning:
#
#   We can use `asset.doc.type.versions :type tigerdata:rootdoc` to get a list of the versions of a given type.
#   We can use `asset.doc.type.describe :type tigerdata:rootdoc -version 1` to view the definition of a given version.
