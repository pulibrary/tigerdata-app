# 9. Grouper: Roles and Permissions

Date: 2026-01-15

## Status

In discussion

## Context

As designers and administrators of the TigerData system, we need to have a way to efficiently manage collections of users who then can be granted authority in both Mediaflux and the front end based on the roles they hold.

## Decision

Grouper Groups:

- We will utilize Grouper Groups to define roles in the application and Mediaflux.
- We support four roles in the system current: `System Administrator`, `Developer`, `Trainer`, `Researcher`
- There are Grouper groups that define who is a System Administrator, a Developer and a Trainer in Tigerdata. The rest of the folks who login to the system are assumed to be Researchers.

Role application and validation:

- At login, check the user's Grouper data from Mediaflux.
- If the user is in the any of the three previously defined Grouper groups, we ensure that they have the appropriate corresponding role in our application
- If the user is NOT in the any Grouper group, we ensure that they do not have the corresponding role in our application

Role names:

1. `Trainer`
1. `System Administrator`
1. `Developer`
1. `Eligible Data Sponsor`
1. `Eligible Data Manager`

The following role names and permission levels will be enforced via application code:

1. `Trainer` are generally AUX and PRDS team members. This gives the user the ability to view the system as and administrator or a developer.
2. `System Administrators` can view, approve, and reject project requests
3. `Developer` — Previously the `SuperUser` role in our application, grants the RDSS developers the full capabilities of all roles within the application. This allows us to develop and test the functionality of each individual role

The following roles are not yet enforced via application code:

1. `Eligible Data Sponsor`
1. `Eligible Data Manager`

## Consequences

- Mediaflux is our current system of record for the application
- Roles in Mediaflux reflect to the application Grouper roles
- Elible Data Sponsors and Data Managers are roles that we envision for the future, but do not exists as roles in the system
