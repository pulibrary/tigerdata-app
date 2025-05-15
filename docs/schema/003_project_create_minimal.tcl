# Create a project with the minimal set of fields required by the TigerData schema.
#
#   script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/003_project_create_minimal.tcl

set rootCollection "/td-demo-001/dev/tigerdata"
set rootNamespace "/td-demo-001/dev/tigerdataNS"

set projectMediaFluxName "test-minimal"
set ns "NS"
set projectCollection $rootCollection/$projectMediaFluxName
set projectNamespace $rootNamespace/$projectMediaFluxName$ns
set projectDescription "This is just an example description."
set projectDOI "10.34770/az09-0001"
set projectTitle "Test Project 1"
set schemaVersion "v0.8"

# Create a namespace for our test project
set createNS [xvalue exists [asset.namespace.exists :namespace $projectNamespace]]
if { "$createNS" != "true" } \
{
    asset.namespace.create :namespace $projectNamespace
}


# Create the collection for the test project and set the value for the TigerData schema
asset.create \
    :pid path=$rootCollection \
    :namespace $projectNamespace \
    :name $projectMediaFluxName \
    :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true \
    :type "application/arc-asset-collection" \
    :meta < \
        :tigerdataX:resourceDoc < \
            :resource -resourceClass "Project" -resourceID $projectDOI -resourceIDType "DOI" < \
                :title $projectTitle \
                :description -inherited false -discoverable true -trackingLevel "ResourceRecord" $projectDescription \
                :projectID -projectIDType "DOI" -inherited true -discoverable true -trackingLevel "ResourceRecord" $projectDOI \
                :dataSponsor -userID "mjc12" -userIDType "NetID" -discoverable true -inherited true -trackingLevel "ResourceRecord" \
                :dataManager -userID "mjc12" -userIDType "NetID" -discoverable true -inherited true -trackingLevel "ResourceRecord" \
                :projectProvenance < \
                    :schemaVersion $schemaVersion \
                > \
            > \
        > \
    >
