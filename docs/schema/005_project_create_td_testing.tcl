# Create a project with the data from the "td-testing" project in production
# (https://drive.google.com/drive/folders/1co2jp1lKcgi9x9XG3a6sWX5ZlnwhGb8o)
#
#   script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/005_project_create_td_testing.tcl

# Project values
# (I made dataUser "az3007" read-only just to show how to use this attribute)
set projectDirectory "td-testing"
set projectDescription "A project space for testing the end to end functionality of the TigerData service. This is available to the administrative and development team."
set projectDOI "10.60803/2ab8-e794"
set projectTitle "TigerData Administrative Testing"
set schemaVersion "v0.8"
set dataSponsor "curt"
set dataManager "cbentler"
set dataUser1ro "az3007"
set dataUser2 "dd7"
set dataUser3 "knight"
set departmentCode "DFR"
set departmentName "Research Computing"

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
                :dataSponsor -userID $dataSponsor -userIDType "NetID" -discoverable true -inherited true -trackingLevel "ResourceRecord" \
                :dataManager -userID $dataManager -userIDType "NetID" -discoverable true -inherited true -trackingLevel "ResourceRecord" \
                :dataUsers -trackingLevel "ResourceRecord" \
                < \
                    :dataUser -userID $dataUser1ro -userIDType "NetID" -readOnly true -discoverable true -inherited true \
                    :dataUser -userID $dataUser2 -userIDType "NetID" -readOnly false -discoverable true -inherited true \
                    :dataUser -userID $dataUser3 -userIDType "NetID" -readOnly false -discoverable true -inherited true \
                > \
                :departments -discoverable true -trackingLevel "ResourceRecord" \
                < \
                    :department -departmentCode $departmentCode -inherited false $departmentName \
                > \
                :projectProvenance < \
                    :schemaVersion $schemaVersion \
                > \
            > \
        > \
    >
