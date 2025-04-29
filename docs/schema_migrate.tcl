# Create a namespace and the "root" document type via a TCL script
# and a sample project ("collection asset") with some values.
#
# To run this script form aTerm:
#
#   script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema_migrate.tcl

# Define where our document type will be located (e.g. tigerdataX:resourceDoc)
set namespace "tigerdataX"
set rootDoc "resourceDoc"
set schemaVersion "v0.8"

# Define where our test document will be located (e.g. /td-demo-001/dev/tigerdataNS/april29-test)
set assetTest "april29-test1047"
set ns "NS"
set assetTestNS $assetTest$ns

# Create the namespace for the metadata definition
asset.doc.namespace.update :create true :namespace $namespace

# Define "resource" as defined in the TigerData schemaVersion
#
# Notice that we are using $rootDoc as our root and "resource" as an element of it because
# MediaFlux does not allow attributes as part of the type, attributes are allowed as part
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
            :element -name schemaVersion -min-occurs 1 -max-occurs 1 -type string < :value $schemaVersion -as constant > \
        > \
    > \
>

# Versioning:
#
#   We can use `asset.doc.type.versions :type tigerdata:rootdoc` to get a list of the versions of a given type.
#   We can use `asset.doc.type.describe :type tigerdata:rootdoc -version 1` to view the definition of a given version.
#
# Validating:
# asset.meta.validate :id 1059
#   :invalid -id "1059" -version "2" -nb "1" "XPath tigerdata:project is invalid: missing element 'new_req_element'"
#    :invalid -id "1059" -version "2" -nb "2" "XPath tigerdata:project is invalid: missing element 'another_element'"


# Create a namespace for our test project
asset.namespace.create :namespace /td-demo-001/dev/tigerdataNS/$assetTestNS

# Create the collection for the test project
# with the values defined in github.com/pulibrary/tigerdata-app/issues/1401
asset.create \
    :pid path=/td-demo-001/dev/tigerdata \
    :namespace /td-demo-001/dev/tigerdataNS/$assetTestNS \
    :name $assetTest \
    :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true \
    :type "application/arc-asset-collection" \
    :meta < \
    :tigerdataX:resourceDoc < \
        :resource -resourceClass "Project" -resourceID "10.34770/az09-0011" -resourceIDType "DOI" < \
          :title "Test Proof of Concept Project 1" \
          :projectID -projectIDType "DOI" "10.34770/az09-0011" \
          :projectProvenance < \
            :schemaVersion "v0.8" \
          > \
        > \
    > \
  >