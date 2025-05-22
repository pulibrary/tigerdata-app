# Create a project with the data from the "Blue Mountain" project in production
# (https://drive.google.com/drive/folders/1co2jp1lKcgi9x9XG3a6sWX5ZlnwhGb8o)
#
#   script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/004_project_create_blue_mountain.tcl

# Project values
set projectDirectory "blue-mountain"
set projectDescription "This collection contains important periodicals of the European avant-garde."
set projectDOI "10.60803/bwab-b757"
set projectTitle "Blue Mountain"
set schemaVersion "v0.8"
set dataSponsor "sayers"
set dataManager "gpmenos"
set dataUser "cwulfman"
set departmentCode "LIB-PU"
set departmentName "Library"

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
                :departments -discoverable true -trackingLevel "ResourceRecord" < \
                    :department -departmentCode $departmentCode -inherited false $departmentName \
                > \
                :projectProvenance < \
                    :schemaVersion $schemaVersion \
                > \
            > \
        > \
    >
