# Document creation script.
#
#   Server: 9047
#   Date:   Tue May 06 21:13:58 UTC 2025


if { [ xvalue "exists" [ asset.doc.namespace.exists :namespace "tigerdataX" ]] == "false" } {
    asset.doc.namespace.update :create "true" :namespace "tigerdataX"
}

# Document: tigerdataX:resource [version 1]
#
asset.doc.type.update :create yes :type tigerdataX:resource \
  :label "tigerdataX:resource" \
  :description "root node manually updated" \
  :definition < \
    :element -name "projectID" -type "enumeration" -max-occurs "1" \
    < \
      :restriction -base "enumeration" \
      < \
        :value "10.34770/az09-0011" \
      > \
      :attribute -name "projectIDType" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "DOI" \
        > \
      > \
    > \
    :element -name "projectDirectory" -type "document" -min-occurs "0" -max-occurs "1" \
    < \
      :element -name "requestedValue" -type "enumeration" -max-occurs "1" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "/tigerdata/mjc12/test-poc-1" \
        > \
      > \
    > \
    :element -name "title" -type "string" -max-occurs "1" \
    :element -name "projectProvenance" -type "document" -min-occurs "0" -max-occurs "1" \
    < \
      :element -name "schemaVersion" -type "double" -max-occurs "1" \
    > \
    :element -name "dataSponsor" -type "document" -min-occurs "1" -max-occurs "1" \
    < \
      :element
    > \

   >
