# 9. Grouper: Roles and Permissions

Date: 2025-09-08

## Status

Decided

## Context

As designers and administrators of the TigerData system, we need to have a way to efficiently manage collections of users who then can be granted authority in both Mediaflux and the front end based on the roles they hold.

## Decision

Grouper Groups:

- In the initial connection to Grouper, we only need to have manually managed roles. This effort is to establish the base implementation pattern and manually populated groups.
- In this initial trial with grouper, a TigerData presence is established.
- The roles for data managers, developers, and front end system administrator are represented in Grouper

Role application and validation:

- At login, check the user's Grouper data from LDAP
- If the user is in the any of the three prviously defined Grouper groups, we ensure that they have the appropriate corresponding role in our application
- If the user is NOT in the any Grouper group, we ensure that they do not have the corresponding role in our application

Role names:

1. `Data Manager`
2. `System Administrator`
3. `Developer`

The following role names and permission levels will be enforced via application code:

1. `Data Managers` must be trained by PRDS.
2. `System Administrators` can view, approve, and reject project requests
3. `Developer` — Previously the `SuperUser` role in our application, grants the RDSS developers the full capabilities of all roles within the application. This allows us to develop and test the functionality of each individual role

## Consequences

- Not all roles in Grouper is not in place yet, for now we be getting the roles for a user from two different sources. This will need to be updated later in the project.
