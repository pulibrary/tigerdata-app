# Create a project with the minimal set of fields required by the TigerData schema.
#
#   script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/003_project_create_minimal.tcl


# Project values
set projectDirectory "test-minimal-8"
set projectDescription "This is just an example description."
set projectDOI "10.34770/az09-0001"
set projectTitle "Test Project 1"
set schemaVersion "v0.8"


# Mediaflux paths
set ns "NS"
set rootCollection "/td-demo-001/dev/tigerdata"
set rootNamespace "/td-demo-001/dev/tigerdataNS"
set projectCollection $rootCollection/$projectDirectory
set projectNamespace $rootNamespace/$projectDirectory$ns


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
    :name $projectDirectory \
    :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true \
    :type "application/arc-asset-collection" \
    :meta < \
        :tigerdataX:resourceDoc < \
            :resource -resourceClass "Project" -resourceID $projectDOI -resourceIDType "DOI" < \
                :title -lang "en" $projectTitle \
                :description -lang "en" -inherited false -discoverable true -trackingLevel "ResourceRecord" $projectDescription \
                :projectID -projectIDType "DOI" -inherited true -discoverable true -trackingLevel "ResourceRecord" $projectDOI \
                :projectDirectory -inherited false -discoverable false -trackingLevel "InternalUseOnly" -approved true \
                < \
                    :projectDirectoryPath -protocol "NFS" $projectDirectory \
                    :requestedValue -protocol "NFS" $projectDirectory \
                    :approvedValue -protocol "NFS" $projectDirectory \
                > \
                :dataSponsor -userID "mjc12" -userIDType "NetID" -discoverable true -inherited true -trackingLevel "ResourceRecord" \
                :dataManager -userID "mjc12" -userIDType "NetID" -discoverable true -inherited true -trackingLevel "ResourceRecord" \
                :departments -discoverable true -trackingLevel "ResourceRecord" < \
                    :department -departmentCode RDSS -inherited false "Research Data and Scholarly Services" \
                > \
                :projectProvenance < \
                    :schemaVersion $schemaVersion \
                > \
            > \
        > \
    >
