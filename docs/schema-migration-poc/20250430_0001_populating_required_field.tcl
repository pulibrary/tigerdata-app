# Populates the fields in a project. This uses brute force
# sets all the values in the project.
set tdNamespace "tigerdataX"
set tdResourceDoc "resourceDoc"
set collectionPath "/td-demo-001/dev/tigerdata/april29-test502"

set projectId "april29-test502"
set projectDOI "10.34770/az09-0011"
set projectTitle "Test Proof of Concept 1"
set schemaVersion "v0.10"

asset.set  \
    :id path=$collectionPath \
    :meta < \
        :$tdNamespace:$tdResourceDoc < \
            :resource -resourceClass "Project" -resourceID $projectDOI -resourceIDType "DOI" < \
                :title $projectTitle \
                :newRequiredField "new required value" \
                :projectID -projectIDType "DOI" $projectDOI \
                :projectProvenance < \
                    :schemaVersion $schemaVersion \
                > \
            > \
        > \
    >