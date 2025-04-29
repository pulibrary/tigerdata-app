# Create a project and sets the values from our TigerData schema

# Define where our document type will be located (e.g. tigerdataX:resourceDoc)
# We are not using "tigerdata:project" so that we don't pollute the existing schema in our Mediaflux instances.
set tdNamespace "tigerdataX"
set tdResourceDoc "resourceDoc"
set schemaVersion "v0.8"

set rootCollection "/td-demo-001/dev/tigerdata"
set rootNamespace "/td-demo-001/dev/tigerdataNS"

set projectId "april29-test502"
set ns "NS"
set projectCollection $rootCollection/$projectId
set projectNamespace $rootNamespace/$projectId$ns
set projectDOI "10.34770/az09-0011"
set projectTitle "Test Proof of Concept 1"

# Create a namespace for our test project
asset.namespace.create :namespace $projectNamespace

# Create the collection for the test project and set the value for the TigerData schema
asset.create \
    :pid path=$rootCollection \
    :namespace $projectNamespace \
    :name $projectId \
    :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true \
    :type "application/arc-asset-collection" \
    :meta < \
        :$tdNamespace:$tdResourceDoc < \
            :resource -resourceClass "Project" -resourceID $projectDOI -resourceIDType "DOI" < \
                :title $projectTitle \
                :projectID -projectIDType "DOI" $projectDOI \
                :projectProvenance < \
                    :schemaVersion $schemaVersion \
                > \
            > \
        > \
    >