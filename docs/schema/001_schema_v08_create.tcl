# Create a namespace and the "root" document type via a TCL script.
#
# You can run this script form aTerm:
#
#   script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/001_schema_v08_create.tcl
#
# Or directly from the Terminal:
#   java -Dmf.host=0.0.0.0 -Dmf.port=8888 -Dmf.transport=http -Dmf.domain=system -Dmf.user=manager -Dmf.password=change_me -jar aterm.jar --app exec script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/001_schema_v08_create.tcl
#

# As of this version it defines the `resource` and the following project fields within the resource:
#   * projectID
#   * alternativeIDs
#   * parentProject
#   * title
#   * description
#   * languages (missing)
#   * dataSponsor
#           Q. allow incomplete dates in `nameDate` vs Mediaflux date restriction?
#   * dataManager
#   * dataUsers
#   * projectProvenance (incomplete, only includes schemaVersion)
#   * researchDomains (missing)
#   * departments (missing)
#   * projectDirectory
#   * storageAndAccess (missing)
#   * additionalProjectInformation (missing)
#   * supplementalMetadata (missing)


# Define where our document type will be located (e.g. tigerdataX:resourceDoc)
# We are not using "tigerdata:project" so that we don't pollute the existing schema in our Mediaflux instances.
set namespace "tigerdataX"
set rootDoc "resourceDoc"
set schemaVersion "v0.8"

# Create the namespace for the metadata definition
asset.doc.namespace.update :create true :namespace $namespace

# Define "resource" as per the proof of concept schema
# indicated in https://github.com/pulibrary/tigerdata_metadata_schema/blob/main/schemas/standard/TigerData_StandardMetadataSchema_v0.8.xsd
#
# Notice that we are using $rootDoc as our document type and "resource" as an element of it because
# MediaFlux does not allow attributes as part of the document type, attributes are allowed as part
# of elements.
#
asset.doc.type.update :create true :description "Document type to represent TigerData resources (projects and items)." \
    :type $namespace:$rootDoc \
    :definition \
    < \
        :element -name resource -type document < \
            :description "Root element of any metadata record for TigerData resources (projects and items)." \
            :attribute -name "resourceClass" -min-occurs "1" -type "enumeration" \
            < \
                :description "Specifies the class of a given resource: either Project or Item (required)" \
                :restriction -base "enumeration" \
                < \
                :value "Project" \
                :value "Item" \
                > \
            > \
            :attribute -name resourceID -min-occurs "1" -type string \
            < \
               :description "The unique identifier for the resource within TigerData systems (required)" \
            > \
            :attribute -name resourceIDType -min-occurs "1" -type "enumeration" \
            < \
                :description "If the resourceClass is Project, then the resourceID should be a DOI; if Item, then the resourceID should be a Mediaflux AssetID (MFAID)" \
                :restriction -base "enumeration" \
                < \
                :value "DOI" \
                :value "MFAID" \
                > \
            > \
            :element -name projectID -type string -min-occurs 1 -max-occurs 1 < \
                :description "The universally unique identifier for the project (required)" \
                :attribute -name "projectIDType" -type "enumeration" \
                < \
                    :restriction -base "enumeration" \
                    < \
                        :value "DOI" \
                    > \
                    :value -as "constant" "DOI" \
                > \
                :attribute -name inherited -type boolean \
                < \
                    :value -as "default" false \
                > \
                :attribute -name discoverable -type boolean \
                < \
                    :value -as "default" true \
                > \
                :attribute -name trackingLevel -type string \
                < \
                    :value -as "constant" "ResourceRecord" \
                > \
            > \
            :element -name parentProject -type string -min-occurs 0 -max-occurs 1 < \
                :description "The ID of the project to which the resource belongs directly" \
                :attribute -name projectIDType -type string \
                < \
                    :value -as "constant" "DOI" \
                > \
                :attribute -name inherited -type boolean \
                < \
                    :value -as "default" false \
                > \
                :attribute -name discoverable -type boolean \
                < \
                    :value -as "default" true \
                > \
                :attribute -name trackingLevel -type string \
                < \
                    :value -as "default" "ResourceRecord" \
                > \
            > \
            :element -name title -type string -min-occurs 1 -max-occurs 1 \
            :element -name description -type string -min-occurs 1 -max-occurs 1 \
            < \
                :description "A plain-language description of the resource and/or its contents" \
                :instructions "May apply to either Projects or Items" \
                :attribute -name inherited -type boolean \
                < \
                    :value -as default false \
                > \
                :attribute -name discoverable -type boolean \
                < \
                    :value -as default true \
                > \
                :attribute -name trackingLevel -type string \
                < \
                    :value -as default "ResourceRecord" \
                > \
            > \
            :element -name projectDirectory -type document -min-occurs 1 -max-occurs 1 \
            < \
                :description "The locally unique name for the project's directory" \
                :instructions "The typical value is expected to be in NFS protocol. A parent folder is recommended to organize projects by groups (e.g., lab or principal investigator). If no user request was received and no value has yet been approved, then this field may be empty." \
                :attribute -name inherited -type boolean \
                < \
                    :value -as constant false \
                > \
                :attribute -name discoverable -type boolean \
                < \
                    :value -as constant false \
                > \
                :attribute -name trackingLevel -type string \
                < \
                    :value -as constant "InternalUseOnly" \
                > \
                :attribute -name approved -type boolean \
                < \
                    :value -as default false \
                > \
                :element -name projectDirectoryPath -type string -min-occurs 0 -max-occurs 100 \
                < \
                    :description "A current setting for projectDirectory (omitted until approved)" \
                    :instructions "After approval, this value should be updated to match the approved value (in rare cases, the current setting may later deviate from the approved value). Multiple elements are allowed to specify paths in alternative protocols, using the protocol attribute. Example NFS path: /tigerdata/parent-folder/project-folder. Example SMB path: \\tigerdata-smb\parent-folder\project-folder. Example S3 path: S3://princeton/tigerdata/parent-folder/project-folder." \
                > \
                :element -name requestedValue -type string -min-occurs 0 -max-occurs 1 \
                < \
                    :description "A current setting for projectDirectory (omitted until approved)" \
                    :instructions "After approval, this value should be updated to match the approved value (in rare cases, the current setting may later deviate from the approved value). Multiple elements are allowed to specify paths in alternative protocols, using the protocol attribute. Example NFS path: /tigerdata/parent-folder/project-folder. Example SMB path: \\tigerdata-smb\parent-folder\project-folder. Example S3 path: S3://princeton/tigerdata/parent-folder/project-folder." \
                > \
                :element -name approvedValue -type string -min-occurs 0 -max-occurs 1 \
                < \
                    :description "The approved value for projectDirectory (omitted if no sys admin has approved yet)" \
                    :instructions "Once approved, the approved attribute should also be set to true." \
                > \
            > \
            :element -name projectProvenance -type document -min-occurs 1 -max-occurs 1 \
            < \
                :element -name schemaVersion -min-occurs 1 -max-occurs 1 -type string < :value $schemaVersion -as default > \
            > \
            :element -name "alternativeIDs" -type "document" -min-occurs "0" -max-occurs "1" -label "The container element for all alternative IDs for a resource" \
            < \
                :description "May apply to either Projects or Items" \
                :instructions "If this element is present, then it should contain at least one sub-element" \
                :element -name "alternativeID" -type "string" -max-occurs "100" \
                < \
                    :description "An alternative identifier for the resource (not the standard TigerData projectID or itemID), given as a string. Modeled after the DataCite definition for RelatedIdentifier (v4.6+)" \
                    :instructions "May apply to either Projects or Items" \
                    :attribute -name "alternativeIDType" -type "string" \
                    < \
                        :description "A simple description of the alternative ID type (e.g. Local accession number)" \
                    > \
                    :attribute -name "inherited" -type "boolean" \
                    < \
                        :value -as "default" false \
                    > \
                > \
            > \
            :element -name "dataSponsor" -type "document" -max-occurs "1" \
            < \
                :description "The person who takes primary responsibility for the project" \
                :instructions "Does not apply to Items" \
                :attribute -name userID -min-occurs "1" -type string \
                < \
                    :description "Specifies the (locally) unique user ID" \
                    :instructions "If a value is given for the sub-element netID, then it should match the value given for userID" \
                    :restriction -base "string" \
                    < \
                        :min-length "2" \
                        :max-length "8" \
                        :display-length "8" \
                    > \
                > \
                :attribute -name userIDType -min-occurs "1" -type string \
                < \
                    :description "Makes explicit that Princeton NetIDs are always used as the identifier for the userID attribute" \
                    :value -as "constant" "NetID" \
                > \
                :attribute -name inherited -type boolean \
                < \
                    :value -as "default" false \
                > \
                :attribute -name discoverable -type boolean \
                < \
                    :value -as "default" true \
                > \
                :attribute -name "trackingLevel" -type "enumeration" \
                < \
                    :description "Standard attribute to specify the tracking level of a given field" \
                    :restriction -base "enumeration" \
                    < \
                        :value "ResourceRecord" \
                    > \
                    :value -as "constant" "ResourceRecord" \
                > \
                :element -name "netID" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The Princeton University NetID (also called the OIT NetID) is the name or user-id that identifies a person to a computer system or electronic service at Princeton." \
                    :restriction -base "string" \
                    < \
                    :min-length "2" \
                    :max-length "8" \
                    :display-length "8" \
                    > \
                > \
                :element -name "PUID" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The Princeton University ID (aka Student ID, Employee ID, EMPLID, Princeton ID, or PUID) is a unique nine digit identifier assigned to an individual who has an official affiliation with the University." \
                > \
                :element -name "orcid" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The ORCID ID URL for the person in a given role, if available and if verified as valid against the ORCID API upon entry." \
                > \
                :element -name "fullName" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The full name of the person in a given role, verified in the format family-comma-given and matching the corresponding given and family name fields, if available." \
                > \
                :element -name "givenName" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The given name(s) of the person in a given role. If the person has multiple given names, then all should be included in this field, along with any suffixes." \
                > \
                :element -name "familyName" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The family name(s) of the person in a given role. If the person has multiple family names, then all should be included in this field." \
                > \
                :element -name "alternativeNameIdentifier" -type "string" -min-occurs "0" -max-occurs "100" \
                < \
                    :description "Records alternative (non-ORCID) identifier(s) for the person in a given role." \
                    :attribute -name nameIdentifierScheme -min-occurs "1" -type string \
                    < \
                        :description "The name of the scheme to which the name identifier belongs (required when an alternative name identifier is given)." \
                    > \
                    :attribute -name schemeURI -min-occurs "1" -type url \
                    < \
                        :description "The URI of the scheme to which the name identifier belongs (required when an alternative name identifier is given)." \
                    > \
                > \
                :element -name "nameDate" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The date at which the name metadata was recorded." \
                    :instructions "Applies a pattern aligned with RKMS-ISO8601 https://www.ukoln.ac.uk/metadata/dcmi/collection-RKMS-ISO8601" \
                > \
            > \
            :element -name "dataManager" -type "document" -max-occurs "1" \
            < \
                :description "The person who manages the day-to-day activities for the project" \
                :instructions "Does not apply to Items" \
                :attribute -name userID -min-occurs "1" -type string \
                < \
                    :description "Specifies the (locally) unique user ID" \
                    :instructions "If a value is given for the sub-element netID, then it should match the value given for userID" \
                    :restriction -base "string" \
                    < \
                        :min-length "2" \
                        :max-length "8" \
                        :display-length "8" \
                    > \
                > \
                :attribute -name userIDType -min-occurs "1" -type string \
                < \
                    :description "Makes explicit that Princeton NetIDs are always used as the identifier for the userID attribute" \
                    :value -as "constant" "NetID" \
                > \
                :attribute -name inherited -type boolean \
                < \
                    :value -as "default" false \
                > \
                :attribute -name discoverable -type boolean \
                < \
                    :value -as "default" true \
                > \
                :attribute -name "trackingLevel" -type "enumeration" \
                < \
                    :description "Standard attribute to specify the tracking level of a given field" \
                    :restriction -base "enumeration" \
                    < \
                        :value "ResourceRecord" \
                    > \
                    :value -as "constant" "ResourceRecord" \
                > \
                :element -name "netID" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The Princeton University NetID (also called the OIT NetID) is the name or user-id that identifies a person to a computer system or electronic service at Princeton." \
                    :restriction -base "string" \
                    < \
                        :min-length "2" \
                        :max-length "8" \
                        :display-length "8" \
                    > \
                > \
                :element -name "PUID" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The Princeton University ID (aka Student ID, Employee ID, EMPLID, Princeton ID, or PUID) is a unique nine digit identifier assigned to an individual who has an official affiliation with the University." \
                > \
                :element -name "orcid" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The ORCID ID URL for the person in a given role, if available and if verified as valid against the ORCID API upon entry." \
                > \
                :element -name "fullName" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The full name of the person in a given role, verified in the format family-comma-given and matching the corresponding given and family name fields, if available." \
                > \
                :element -name "givenName" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The given name(s) of the person in a given role. If the person has multiple given names, then all should be included in this field, along with any suffixes." \
                > \
                :element -name "familyName" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The family name(s) of the person in a given role. If the person has multiple family names, then all should be included in this field." \
                > \
                :element -name "alternativeNameIdentifier" -type "string" -min-occurs "0" -max-occurs "100" \
                < \
                    :description "Records alternative (non-ORCID) identifier(s) for the person in a given role." \
                    :attribute -name nameIdentifierScheme -min-occurs "1" -type string \
                    < \
                        :description "The name of the scheme to which the name identifier belongs (required when an alternative name identifier is given)." \
                    > \
                    :attribute -name schemeURI -min-occurs "1" -type url \
                    < \
                        :description "The URI of the scheme to which the name identifier belongs (required when an alternative name identifier is given)." \
                    > \
                > \
                :element -name "nameDate" -type "string" -min-occurs "0" -max-occurs "1" \
                < \
                    :description "The date at which the name metadata was recorded." \
                    :instructions "Applies a pattern aligned with RKMS-ISO8601 https://www.ukoln.ac.uk/metadata/dcmi/collection-RKMS-ISO8601" \
                > \
            > \
            :element -name "dataUsers" -type "document" -min-occurs "0" -max-occurs "1" \
            < \
                :description "The container element for all data users of a resource" \
                :instructions "May apply to either Projects or Items. If this element is present, then it should contain at least one sub-element" \
                :attribute -name "trackingLevel" -type "enumeration" \
                < \
                    :description "Standard attribute to specify the tracking level of a given field" \
                    :restriction -base "enumeration" \
                    < \
                        :value "ResourceRecord" \
                    > \
                    :value -as "constant" "ResourceRecord" \
                > \
                :element -name "dataUser" -type "document"  -min-occurs "1" -max-occurs "100" \
                < \
                    :description "A person who has access privileges to the resource" \
                    :instructions "May apply to either Projects or Items" \
                    :attribute -name inherited -type boolean \
                    < \
                        :value -as "default" true \
                    > \
                    :attribute -name discoverable -type boolean \
                    < \
                        :value -as "default" false \
                    > \
                    :attribute -name "readOnly" -type boolean -min-occurs "1" \
                    < \
                        :description "Specifies whether the data user has read-only access to the resource (if false, then read-write access is granted)" \
                        :value -as "default" true \
                    > \
                    :attribute -name userID -min-occurs "1" -type string \
                    < \
                        :description "Specifies the (locally) unique user ID" \
                        :instructions "If a value is given for the sub-element netID, then it should match the value given for userID" \
                    > \
                    :attribute -name userIDType -min-occurs "1" -type string \
                    < \
                        :description "Makes explicit that Princeton NetIDs are always used as the identifier for the userID attribute" \
                        :value -as "constant" "NetID" \
                    > \
                    :element -name "netID" -type "string" -min-occurs "0" -max-occurs "1" \
                    < \
                        :description "The Princeton University NetID (also called the OIT NetID) is the name or user-id that identifies a person to a computer system or electronic service at Princeton." \
                        :restriction -base "string" \
                        < \
                            :min-length "2" \
                            :max-length "8" \
                            :display-length "8" \
                        > \
                    > \
                    :element -name "PUID" -type "string" -min-occurs "0" -max-occurs "1" \
                    < \
                        :description "The Princeton University ID (aka Student ID, Employee ID, EMPLID, Princeton ID, or PUID) is a unique nine digit identifier assigned to an individual who has an official affiliation with the University." \
                    > \
                    :element -name "orcid" -type "string" -min-occurs "0" -max-occurs "1" \
                    < \
                        :description "The ORCID ID URL for the person in a given role, if available and if verified as valid against the ORCID API upon entry." \
                    > \
                    :element -name "fullName" -type "string" -min-occurs "0" -max-occurs "1" \
                    < \
                        :description "The full name of the person in a given role, verified in the format family-comma-given and matching the corresponding given and family name fields, if available." \
                    > \
                    :element -name "givenName" -type "string" -min-occurs "0" -max-occurs "1" \
                    < \
                        :description "The given name(s) of the person in a given role. If the person has multiple given names, then all should be included in this field, along with any suffixes." \
                    > \
                    :element -name "familyName" -type "string" -min-occurs "0" -max-occurs "1" \
                    < \
                        :description "The family name(s) of the person in a given role. If the person has multiple family names, then all should be included in this field." \
                    > \
                    :element -name "alternativeNameIdentifier" -type "string" -min-occurs "0" -max-occurs "100" \
                    < \
                        :description "Records alternative (non-ORCID) identifier(s) for the person in a given role." \
                        :attribute -name nameIdentifierScheme -min-occurs "1" -type string \
                        < \
                            :description "The name of the scheme to which the name identifier belongs (required when an alternative name identifier is given)." \
                        > \
                        :attribute -name schemeURI -min-occurs "1" -type url \
                        < \
                            :description "The URI of the scheme to which the name identifier belongs (required when an alternative name identifier is given)." \
                        > \
                    > \
                    :element -name "nameDate" -type "string" -min-occurs "0" -max-occurs "1" \
                    < \
                        :description "The date at which the name metadata was recorded." \
                        :instructions "Applies a pattern aligned with RKMS-ISO8601 https://www.ukoln.ac.uk/metadata/dcmi/collection-RKMS-ISO8601" \
                    > \
                > \
            > \
        > \
    >
