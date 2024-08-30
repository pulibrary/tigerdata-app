# TigerData Schema Overall Structure

An opinionated summary of some of the most important parts of the TigerData XML schema referenced in [GitHub issue #186](https://github.com/pulibrary/tigerdata-app/issues/896): https://drive.google.com/file/d/1qrdPXwAt57uqPmHxh0Y86zac4RvtoJ2e/view

This is a human created summary. The source of truth is the XML schema referenced above.

The schema defines both `primitives` (types, attributes, elements, groups) and the `payload` (i.e. the root element).


## Root
The Root element of any metadata record for TigerData is the `resource`. This can be used for both Projects and Items.

If the `resourceClass` of the `resource` is `Project`, then the `projectFields` group must be used. If the `resourceClass` is `Item`, then the `itemFields` group must be used.


* `projectFields`: A group of all elements/groups included in the TigerData standard metadata for projects.

  This includes `projectID`, `alternativeIDs`, `parentProject`, `projectRoles`, `projectDescription`, `storageAndAccess`, `additionalProjectInformation`, `supplementalMetadata`, and `projectProvenance`.

  Does not apply to Items.

* `itemFields`: A group of all elements/groups included in the TigerData standard metadata for items.

  This includes: `itemID`, `alternativeIDs`, `parentProject`, `dataUsers`, `title`, `description`, `resourceType`, `supplementalMetadata`, `languages`, `licenses`, `fundingReferences`, `duaReferences`, and `dates`.

  Does not apply to Projects.


## Common Types

All of the types, attributes, elements, and groups that are combined to make up a standard metadata payload (defined below)

Common Types:
Simple and complex types that are either necessary building blocks for further types or that have application in various places (e.g., both elements and attributes)

* `doiType`: Standard type used for DOI values (just the prefix and suffix; not a full URL).
* `projectIDValueType`: Standard type for the values of projectID and parentProject fields. Applies to both Projects and Items.
* `netIDType`: Standard type used for values meant to be a Princeton NetID.
* `limitedTextType`: Specification for the practical limit applied to free text values</xs:documentation>
* `textType`: Standard type used for free text values
* `pathSafeType`: Primitive type used within pathType. Restricts to alphanumeric characters, underscore, forward and back slashes, and minus-dash.
* `byteUnitType`: Standard type that defines the controlled vocabulary for byte units in storageQuantityType (B, KB, MB, ...)
* `dateOrRangeType`: Standard type used for values that may be either dates or date ranges.


## Attribute Types
* `trackingLevelType`: Standard type that defines the controlled vocabulary for the trackingLevel attribute
  * `ResourceRecord`: The field should be included in any long-term or crosswalked records for the resource
  * `InternalUseOnly`: The field is intended for internal (Princeton) use only
* `resourceTypeGeneralType`
* `licenseURIType`
* `licenseIDType`


## Common Attributes
* `inherited`
* `discoverable`
* `trackingLevel`
* `resourceTypeGeneral`


## Element Types
* `userType`
* `researchDomainNameType`
* `pathType`
* `quantityType`


## Common Elements
* `alternativeID`: An alternative identifier for the resource (not the standard TigerData projectID or itemID).
* `alternativeIDs`: The container element for all alternative IDs for a resource.
* `parentProject`: The ID of the project to which the resource belongs directly. Applies to both Projects and Items. Takes precedence over any IsChildOf relations to other projects.
* `dataSponsor`: The person who takes primary responsibility for the project. Does not apply to Items.
* `dataManager`: The person who manages the day-to-day activities for the project. Does not apply to Items.
* `dataUser`: A person who has access privileges to the resource. May apply to either Projects or Items.


## Subelement Groups
* `provenaneSubfields`


## Element Groups
* `projectRoles`: A group of all elements included in TigerData project roles.

  Does not apply to Items.

  Includes `dataSponsor`, `dataManager`, and `dataUsers` (`dataUsers` in turn includes many `dataUser`)

* `projectDescription`: A group of all elements included in TigerData project descriptions.

  Does not apply to Items.

  Includes `researchDomains`, `departments`, `projectDirectory`, `title`, `description`, and `languages`

* `storageAndAccess`: A group of all elements included in TigerData project storage and access needs.

  Does not apply to Items.

* `additionalProjectInformation`: A group of all elements included in TigerData additional project information fields.

  Does not apply to Items.

* `supplementalMetadata`: A group of all elements included in TigerData supplemental metadata fields.

  May apply to either Projects and Items.

