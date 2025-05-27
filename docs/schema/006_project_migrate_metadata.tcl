# Copies the metadata from the tigerdata:project schema to the new fields defined
# for the tigerdataX:resourceDoc schema.
#
# You can run this script form aTerm:
#   script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/006_project_migrate_metadata.tcl
#


# Fetch the current data for the project
set assetId 1123
set asset [asset.get :id $assetId]
set oldTitle [xvalue asset/meta/tigerdata:project/Title $asset]
set oldDescription [xvalue asset/meta/tigerdata:project/Description $asset]
set oldDataSponsor [xvalue asset/meta/tigerdata:project/DataSponsor $asset]
set oldDataManager [xvalue asset/meta/tigerdata:project/DataManager $asset]
set oldProjectID [xvalue asset/meta/tigerdata:project/ProjectID $asset]
set oldProjectDirectory [xvalue asset/meta/tigerdata:project/ProjectDirectory $asset]
set oldDepartmentCode [xvalue asset/meta/tigerdata:project/Department $asset]
# TODO: map the department codes to names
set oldDepartmentName "(pending)"
set schemaVersion "0.8"


# Update the fields in the new metadata schema with the data from the old schema
asset.set  \
    :id $assetId \
    :meta < \
        :tigerdataX:resourceDoc < \
            :resource -resourceClass "Project" -resourceID $oldProjectID -resourceIDType "DOI" < \
                :title -lang "en" $oldTitle \
                :description -lang "en" -inherited false -discoverable true -trackingLevel "ResourceRecord" $oldDescription \
                :projectID -projectIDType "DOI" -inherited true -discoverable true -trackingLevel "ResourceRecord" $oldProjectID \
                :projectDirectory -inherited false -discoverable false -trackingLevel "InternalUseOnly" -approved true \
                < \
                    :projectDirectoryPath -protocol "NFS" $oldProjectDirectory \
                    :requestedValue -protocol "NFS" $oldProjectDirectory \
                    :approvedValue -protocol "NFS" $oldProjectDirectory \
                > \
                :dataSponsor -userID $oldDataSponsor -userIDType "NetID" -discoverable true -inherited true -trackingLevel "ResourceRecord" \
                :dataManager -userID $oldDataManager -userIDType "NetID" -discoverable true -inherited true -trackingLevel "ResourceRecord" \
                :departments -discoverable true -trackingLevel "ResourceRecord" < \
                    :department -departmentCode $oldDepartmentCode -inherited false $oldDepartmentName \
                > \
                :projectProvenance < \
                    :schemaVersion $schemaVersion \
                > \
            > \
        > \
    >


# You can view the value logged via:
#   server.log.display :name migrate :last 10
#
server.log :app "migrate" :event info :msg "Migrate data for project ${assetId} ${oldTitle}"
