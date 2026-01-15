# 12. Definition of the TigerData systems of record.

Date: 2026-01-15

## Status

Discussion

## Context

We as a team want to organize our system tests so that there are directories for each type of user, so that we can create and locate tests that match up to user stories for each type of user. There are currently three user types; sysadmin user, researcher user, and tester-trainer user.

## Decision

As we refactor existing system tests and whenever we create new system tests, they will be placed in the correct folder cooresponding to the user type, as follows:

Sysadmins: sysadmin_user
Regular users: researcher_user
Tester-trainers: trainer_user

```md
tigerdata-app/
├── spec/
├── system/
├── sysadmin_user/
├── researcher_user/
└── trainer_user/
```

## Consequences

When we create new system tests and when we refactor existing ones, we will need to be deliberate about where we place them, because this is a manual process. Ensuring this should be a best practice for PR author(s), and a part of the PR review process for the reviewer(s).

When system tests are structured this way, it will make it easier for us to know where to add new tests and where to create system specs that match up to user stories.
