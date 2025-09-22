# 10. The process for making changes to the main project schema in Mediaflux

Date: 2025-09-22

## Status

Decided

## Context

Mediaflux acts as the backend database for the TigerData service.  Throughout the natural course of development, the schema definition in Mediaflux will expand and change.  With any changes to database schema architectures, care needs to be taken to ensure the continuity of service.  

While Mediaflux acts as the backend database for the service, it is not the same as other database implementations (ex. SQL).  This is due to the fact that Mediaflux is an application unto itself with various connection and communication requirements.  This ADR is then desired by the administration and development team to describe how changes will be made to facilitate the continuity of service. 

## Decision

When a change is made to the metadata schema for the main TigerData project, the said changes will be made optional until remediation work is complete across the system.  

The process for the change will follow this high level path:
1. A change to the metadata schema is defined and accepted by the development teams. 
2. The change will be made to the Mediaflux document type (tigerdata:project / tigerdata:resource). Any new fields will be set as optional and changed fields will accept previously valid values. 
3. Changes will be made to the Mediaflux services for metadata interaction (tigerdata.project.create).  Any new fields will be set as optional and changed fields will accept previously valid values.
4. The front end application will present the new configuration to end users via development updates. 
5. Remediation of previous projects will occur as necessary.
6. The Mediaflux document type and services will be adjusted to enforce required fields/values.

This will adhere to the normal deployment pipeline for TigerData. 

## Consequences
This will allow for the interoperability of the front end with the backend to persist during changes to the metadata schema.  Development within Mediaflux can then be asynchronous to the development work in the web portal.  

Care should be taken to ensure the full cycle is completed for each schema change.  If remediation is not executed in a timely fashion, technical debt can quickly accrue.  

