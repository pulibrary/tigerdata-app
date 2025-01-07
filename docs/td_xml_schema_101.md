# TigerData Schema Overall Structure

An opinionated summary of some of the most important parts of the TigerData XML schema referenced in [GitHub issue #186](https://github.com/pulibrary/tigerdata-app/issues/896): https://drive.google.com/file/d/1qrdPXwAt57uqPmHxh0Y86zac4RvtoJ2e/view

This is a human created summary and it includes copied and pasted sections from the actual schema (e.g. the description text for the elements were taken and tweaked from the actual schema.) When in doubt, the source of truth is the XML schema referenced above.

The XML schema defines both `primitives` (types, attributes, elements, groups) and the `payload` (i.e. the root element).

The XML schema is defined from the most granular type to the root element, since that's the way the XML standard prescribes it. This summary presents the data in the opposite direction: starting at the root and then diving into the more granular elements.

## Root

The Root element of any metadata record for TigerData is the `resource`. This can be used for both `Projects` and `Items` in TigerData. In this context `Items` refer to files within the project.

If the `resourceClass` of the `resource` is `Project` then fields from the `projectFields` group must be used. If the `resourceClass` is `Item` then fields from the `itemFields` group must be used.

Below is an snipet of a project definition, notice the `resourceClass` defines that this is a `Project`:

```
<resource resourceClass="Project" resourceID="10.34770/az09-0001" resourceIDType="DOI">
  <projectID projectIDType="DOI" inherited="false" discoverable="true" trackingLevel="ResourceRecord">10.34770/az09-0001</projectID>
  ...
</resource>
```

At this point we have not explored how, in practice, `Items` are going to be managed within a `resource`, but in theory the schema supports managing both: `Projects` and `Items`.

## Project Fields and Item Fields

There are two distinctive groups within the TigerData schema: `projectFields` and `itemFields`.

- `projectFields`: A group of all elements/groups included in the TigerData standard metadata for projects.

  This includes `projectID`, `alternativeIDs`, `parentProject`, `projectRoles`, `projectDescription`, `storageAndAccess`, `additionalProjectInformation`, `supplementalMetadata`, and `projectProvenance`.

- `itemFields`: A group of all elements/groups included in the TigerData standard metadata for items.

  This includes: `itemID`, `alternativeIDs`, `parentProject`, `dataUsers`, `title`, `description`, `resourceType`, `supplementalMetadata`, `languages`, `licenses`, `fundingReferences`, `duaReferences`, and `dates`.

Notice that `projectFields` apply only to projects (i.e. not to items), whereas the reverse is true for `itemFields` (i.e. they apply only to items and not to projects). However, although `projectFields` and `itemFields` are mutually exclusive they do share a lot of types and attribute types.

## Element Groups

Group definitions for elements, including some reference to common elements (see next section) and some new element definitions within:

- `projectRoles`: A group of all elements included in TigerData project roles.

  Does not apply to Items.

  Includes `dataSponsor`, `dataManager`, and `dataUsers` (`dataUsers` in turn includes many `dataUser`)

- `projectDescription`: A group of all elements included in TigerData project descriptions.

  Does not apply to Items.

  Includes `researchDomains`, `departments`, `projectDirectory`, `title`, `description`, and `languages`.

  **Note:** `projectDescription` and `description` will be source of confusion, could we rename one of them?

- `storageAndAccess`: A group of all elements included in TigerData project storage and access needs.

  Does not apply to Items.

- `additionalProjectInformation`: A group of all elements included in TigerData additional project information fields.

  Does not apply to Items.

- `supplementalMetadata`: A group of all elements included in TigerData supplemental metadata fields.

  May apply to either Projects and Items.

## Common Types

Simple and complex types that are either necessary building blocks for further types or that have application in various places (e.g., both elements and attributes)

- `doiType`: Standard type used for DOI values (just the prefix and suffix; not a full URL).
- `projectIDValueType`: Standard type for the values of projectID and parentProject fields. _Applies to both Projects and Items._
- `netIDType`: Standard type used for values meant to be a Princeton NetID.
- `limitedTextType`: Specification for the practical limit applied to free text values.
- `textType`: Standard type used for free text values
- `pathSafeType`: Primitive type used within pathType. Restricts to alphanumeric characters, underscore, forward and back slashes, and minus-dash.
- `byteUnitType`: Standard type that defines the controlled vocabulary for byte units in storageQuantityType (B, KB, MB, ...)
- `dateOrRangeType`: Standard type used for values that may be either dates or date ranges.

## Common Elements

Element definitions that appear in multiple groups and/or apply to both projects and items:

- `alternativeID`: An alternative identifier for the resource (not the standard TigerData projectID or itemID).
- `alternativeIDs`: The container element for all alternative IDs for a resource.
- `parentProject`: The ID of the project to which the resource belongs directly. _Applies to both Projects and Items._
- `dataSponsor`: The person who takes primary responsibility for the project. Does not apply to Items.
- `dataManager`: The person who manages the day-to-day activities for the project. Does not apply to Items.
- `dataUser`: A person who has access privileges to the resource. _May apply to either Projects or Items._
