# Versioning:
#
#   We can use `asset.doc.type.versions :type tigerdata:rootdoc` to get a list of the versions of a given type.
#   We can use `asset.doc.type.describe :type tigerdata:rootdoc -version 1` to view the definition of a given version.
#
# Validating:
# asset.meta.validate :id 1059
#   :invalid -id "1059" -version "2" -nb "1" "XPath tigerdata:project is invalid: missing element 'new_req_element'"
#    :invalid -id "1059" -version "2" -nb "2" "XPath tigerdata:project is invalid: missing element 'another_element'"


# # Create a namespace for our test project
# asset.namespace.create :namespace /td-demo-001/dev/tigerdataNS/$assetTestNS
#
# # Create the collection for the test project
# # with the values defined in github.com/pulibrary/tigerdata-app/issues/1401
# asset.create \
#     :pid path=/td-demo-001/dev/tigerdata \
#     :namespace /td-demo-001/dev/tigerdataNS/$assetTestNS \
#     :name $assetTest \
#     :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true \
#     :type "application/arc-asset-collection" \
#     :meta < \
#     :tigerdataX:resourceDoc < \
#         :resource -resourceClass "Project" -resourceID "10.34770/az09-0011" -resourceIDType "DOI" < \
#             :title "Test Proof of Concept Project 1" \
#             :projectID -projectIDType "DOI" "10.34770/az09-0011" \
#             :projectProvenance < \
#                 :schemaVersion "v0.8" \
#             > \
#         > \
#     > \
#   >


# asset.set :id 1067 \
#     :meta < \
#     :tigerdataX:resourceDoc < \
#         :resource -resourceClass "Project" -resourceID "10.34770/az09-0011" -resourceIDType "DOI" < \
#             :title "Test Proof of Concept Project 1" \
#             :newField "updated newValue at 328" \
#             :projectID -projectIDType "DOI" "10.34770/az09-0011" \
#             :projectProvenance < \
#                 :schemaVersion "v0.8" \
#             > \
#         > \
#     > \
#   >
#
# asset.meta.value.set :id 1067 :value newValue -xpath tigerdataX:resourceDoc/newField