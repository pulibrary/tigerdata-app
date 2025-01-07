# 3. Roles and Permissions

Date: 2024-01-25

## Status

Discussion

## Context

Different roles have different levels of permission in the application. The goal is to enforce institutional data management policies that can't be enforced directly on mediaflux or via UNIX filesystem permissions.

## Decision

Role names:

1. `Data Sponsor`
2. `Data Manager`
3. `Data User`

The following role names and permission levels will be enforced via application code:

1. A `Data Sponsor` has the highest level of permission. We should assume for now that anyone with a `Data Sponsor` level of permission has effectively been trained in correct data management process.
   1. Persons eligible to be a data sponsor are the only ones who can request a new project.
   2. The user who initiates a request is automatically assigned as the `Data Sponsor` for that project.
   3. `Data Sponsors` are the only people who can assign a `Data Manager`, including post-approval edits.
   4. A `Data Manager` cannot add or edit another `Data Manager`.
2. The `Data Sponsor` and the `Data Manager` can be the same person.
3. `Data Managers` must be trained by PRDS. Those eligible to be `Data Managers` will eventually be managed by a Grouper group. For now, the [Preliminary Registration spreadsheet](https://docs.google.com/spreadsheets/d/169lfRTOSe6H66Iu2DK5g-QzqiVsfz5lHFHMaGmwNT7Y) will contain columns indicating who is eligible to be a `Data Sponsor` or a `Data Manager`.
4. Both `Data Sponsors` and `Data Managers` can assign and edit `Data Users`

## Consequences

- Because Grouper is not in place yet, for now we need to use a temporary solution of a spreadsheet. This will need to be updated later in the project.
- We will need a clear process for how to respond when someone wants to be in a `Data Sponsor` or `Data Manager` role but their information is not on the spreadsheet / in Grouper. For now, send them to Matt Chandler.
- We will need a set of automated tests that ensure that these roles are enforced and that we don't write any functionality later on that breaks them.
- We should also produce an audit process to tell us whether the system is currently following the rules (e.g., to detect whether a disallowed user has been added out of band).
