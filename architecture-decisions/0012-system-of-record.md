# 12. Definition of the TigerData systems of record.

Date: 2025-10-27

## Status

Accepted

## Context

Like many systems on campus, the TigerData is comprised of entities that contain metadata generated and stored in various applications and databases. A simple example of this may be that a data sponsor is associated with a TigerData project, but the details of that sponsor originate from an external system such as LDAP (ultimately from the university's ERP).

When coalescing many different data points from many different systems, it is desirable to understand which systems hold the true source data (the system of record) to ensure that complex synchronization does not need to occur. This is a description of the sources of truth.

## Decision

The following is a mapping of data an the system that should be considered the source of truth.

- Persistent data for approved TigerData projects (with consideration for long term provenance needs) - Mediaflux
- Processing data for the request and approval workflow regarding TigerData projects - The TigerData web portal database
- User account information related to netids - LDAP / AD
- Department and people names and descriptive data - Peoplesoft

## Consequences

### Mediaflux

Only data that needs to persist with a TigerData project should be recorded in Mediaflux. This is a multi directional need, however. While the data needs to be stored in the Mediaflux database, the front end interfaces (including the web portal) should consider actively pulling from Mediaflux as opposed to maintaining a secondary record.

### Provenance

Some provenance data around a project request will only need to be stored in the database connected to the front end web application. This data would be items that are useful for processing, but not necessary for the long term description of the project and actions taken on said project.

### Pass through applications

While it is desirable to connect directly with the system that is the source of truth, it may be more prudent to connect to applications designed for such interfaces. An example of this may be that TigerData gets a list of valid department names from Peoplesoft but any person information is collected via LDAP (even though the source of truth for that data is Peoplesoft).
