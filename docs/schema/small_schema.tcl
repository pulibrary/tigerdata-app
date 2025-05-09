# Document creation script.
# 
#   Server: 9047
#   Date:   Tue May 06 21:37:45 UTC 2025


if { [ xvalue "exists" [ asset.doc.namespace.exists :namespace "tigerdataX" ]] == "false" } {
    asset.doc.namespace.update :create "true" :namespace "tigerdataX"
}

# Document: tigerdataX:resource [version 1]
#
asset.doc.type.update :create yes :type tigerdataX:resource \
  :label "tigerdataX:resource" \
  :description "root node" \
  :definition < \
    :element -name "projectID" -type "enumeration" -max-occurs "1" \
    < \
      :restriction -base "enumeration" \
      < \
        :value "10.34770/az09-0001" \
      > \
      :attribute -name "projectIDType" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "DOI" \
        > \
      > \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "ResourceRecord" \
        > \
      > \
    > \
    :element -name "dataSponsor" -type "string" -min-occurs "0" -max-occurs "1" \
    < \
      :attribute -name "userID" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "mjc12" \
        > \
      > \
      :attribute -name "userIDType" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "NetID" \
        > \
      > \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "ResourceRecord" \
        > \
      > \
    > \
    :element -name "dataManager" -type "string" -min-occurs "0" -max-occurs "1" \
    < \
      :attribute -name "userID" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "mjc12" \
        > \
      > \
      :attribute -name "userIDType" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "NetID" \
        > \
      > \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "ResourceRecord" \
        > \
      > \
    > \
    :element -name "departments" -type "document" -min-occurs "0" -max-occurs "1" \
    < \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "ResourceRecord" \
        > \
      > \
      :element -name "department" -type "string" -max-occurs "1" \
      < \
        :attribute -name "departmentCode" -type "long" \
        :attribute -name "inherited" -type "boolean" \
      > \
    > \
    :element -name "projectDirectory" -type "document" -min-occurs "0" -max-occurs "1" \
    < \
      :attribute -name "approved" -type "boolean" \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "InternalUseOnly" \
        > \
      > \
      :element -name "requestedValue" -type "enumeration" -max-occurs "1" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "/tigerdata/mjc12/test-provisional-1" \
        > \
      > \
      :element -name "approvedValue" -type "enumeration" -max-occurs "1" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "/tigerdata/mjc12/test-provisional-1" \
        > \
      > \
    > \
    :element -name "title" -type "string" -max-occurs "1" \
    < \
      :attribute -name "lang" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "en" \
        > \
      > \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "ResourceRecord" \
        > \
      > \
    > \
    :element -name "description" -type "string" -max-occurs "1" \
    < \
      :attribute -name "lang" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "en" \
        > \
      > \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "ResourceRecord" \
        > \
      > \
    > \
    :element -name "storageCapacity" -type "document" -min-occurs "0" -max-occurs "1" \
    < \
      :attribute -name "approved" -type "boolean" \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "InternalUseOnly" \
        > \
      > \
      :element -name "requestedValue" -type "document" -min-occurs "0" -max-occurs "1" \
      < \
        :element -name "size" -type "long" -max-occurs "1" \
        :element -name "unit" -type "enumeration" -max-occurs "1" \
        < \
          :restriction -base "enumeration" \
          < \
            :value "GB" \
          > \
        > \
      > \
      :element -name "approvedValue" -type "document" -min-occurs "0" -max-occurs "1" \
      < \
        :element -name "size" -type "long" -max-occurs "1" \
        :element -name "unit" -type "enumeration" -max-occurs "1" \
        < \
          :restriction -base "enumeration" \
          < \
            :value "GB" \
          > \
        > \
      > \
    > \
    :element -name "projectVisibility" -type "enumeration" -max-occurs "1" \
    < \
      :restriction -base "enumeration" \
      < \
        :value "Restricted" \
      > \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "InternalUseOnly" \
        > \
      > \
    > \
    :element -name "storagePerformance" -type "document" -min-occurs "0" -max-occurs "1" \
    < \
      :attribute -name "approved" -type "boolean" \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "InternalUseOnly" \
        > \
      > \
      :element -name "requestedValue" -type "enumeration" -max-occurs "1" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "Standard" \
        > \
      > \
      :element -name "approvedValue" -type "enumeration" -max-occurs "1" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "Standard" \
        > \
      > \
    > \
    :element -name "numberOfFiles" -type "string" -max-occurs "1" \
    < \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "InternalUseOnly" \
        > \
      > \
    > \
    :element -name "hpc" -type "boolean" -max-occurs "1" \
    < \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "InternalUseOnly" \
        > \
      > \
    > \
    :element -name "projectPurpose" -type "enumeration" -max-occurs "1" \
    < \
      :restriction -base "enumeration" \
      < \
        :value "Research" \
      > \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "InternalUseOnly" \
        > \
      > \
    > \
    :element -name "provisionalProject" -type "boolean" -max-occurs "1" \
    < \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "InternalUseOnly" \
        > \
      > \
    > \
    :element -name "projectResourceType" -type "string" -max-occurs "1" \
    < \
      :attribute -name "resourceTypeGeneral" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "Project" \
        > \
      > \
      :attribute -name "inherited" -type "boolean" \
      :attribute -name "discoverable" -type "boolean" \
      :attribute -name "trackingLevel" -type "enumeration" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "ResourceRecord" \
        > \
      > \
    > \
    :element -name "projectProvenance" -type "document" -min-occurs "0" -max-occurs "1" \
    < \
      :element -name "submission" -type "document" -min-occurs "0" -max-occurs "1" \
      < \
        :element -name "requestedBy" -type "string" -min-occurs "0" -max-occurs "1" \
        < \
          :attribute -name "userID" -type "enumeration" \
          < \
            :restriction -base "enumeration" \
            < \
              :value "mjc12" \
            > \
          > \
          :attribute -name "userIDType" -type "enumeration" \
          < \
            :restriction -base "enumeration" \
            < \
              :value "NetID" \
            > \
          > \
        > \
        :element -name "requestDateTime" -type "date" -max-occurs "1" \
        :element -name "approvedBy" -type "string" -min-occurs "0" -max-occurs "1" \
        < \
          :attribute -name "userID" -type "enumeration" \
          < \
            :restriction -base "enumeration" \
            < \
              :value "cbentler" \
            > \
          > \
          :attribute -name "userIDType" -type "enumeration" \
          < \
            :restriction -base "enumeration" \
            < \
              :value "NetID" \
            > \
          > \
        > \
        :element -name "approvalDateTime" -type "date" -max-occurs "1" \
      > \
      :element -name "status" -type "enumeration" -max-occurs "1" \
      < \
        :restriction -base "enumeration" \
        < \
          :value "Approved" \
        > \
      > \
      :element -name "schemaVersion" -type "double" -max-occurs "1" \
    > \
   >


# Document: tigerdataX:resourceDoc [version 4]
#
asset.doc.type.update :create yes :type tigerdataX:resourceDoc \
  :label "tigerdataX:resourceDoc" \
  :description "testing doc definition via a TCL script" \
  :definition < \
    :element -name "resource" -type "document" \
    < \
      :attribute -name "resourceClass" -type "string" \
      :attribute -name "resourceID" -type "string" \
      :attribute -name "resourceIDType" -type "string" \
      :element -name "projectID" -type "string" -max-occurs "1" \
      < \
        :attribute -name "projectIDType" -type "string" \
      > \
      :element -name "title" -type "string" -max-occurs "1" \
      :element -name "newOptionalField" -type "string" -min-occurs "0" -max-occurs "1" \
      < \
        :value -as "default" "'something optional'" \
      > \
      :element -name "newRequiredField" -type "string" -max-occurs "1" \
      :element -name "projectProvenance" -type "document" -max-occurs "1" \
      < \
        :element -name "schemaVersion" -type "string" -max-occurs "1" \
        < \
          :value -as "default" "v0.10" \
        > \
      > \
    > \
   >


