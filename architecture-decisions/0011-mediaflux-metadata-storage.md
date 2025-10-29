# 11. Storing metadata in Mediaflux and representing in other metadata schemas

Date: 2025-10-29

## Status

Accepted

## Context

Mediaflux stores project metadata as XML within the Mediaflux database, in ways that are specific to optimized metadata storage and querying by Mediaflux. The TigerData metadata schema is a metadata schema defined by the TigerData Metadata Working Group intended as a schema that defines standards for project metadata in the TigerData service.

## Decision

Project metadata will be stored in Mediaflux in formats that adhere to the standards of the Mediaflux software, for optimization of metadata storage and querying. Metadata stored in Mediaflux will be queried by the TigerData web portal software and returned in the UI as needed to power the frontend as well as in the TigerData metadata schema. The metadata transformation will take place in the web portal software, with data returned from Mediaflux.

## Consequences

This will allow for software development around storing and querying metadata in Mediaflux via the web portal software, and will allow Mediaflux metadata to be represented in the web portal in a variety of metadata schemas as needed in the future. However, enforcement of standards such as required fields for projects will need to be done in the web portal software, informed by rules defined by the schema.
