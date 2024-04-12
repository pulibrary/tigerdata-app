# 7. Valid Statuses for a project

Date: 2024-04-12

## Status
 In discussion


## Context

 - When a project is created in the rails application — the status is recorded within the `status` field of the json-b metadata.
    - It has a limited/ controlled vocabulary of valid options.

## Decision

- Status Options:
    - `Project::PENDING_STATUS` — When a project is created, the status defaults to pending. Meaning it must be reviewed by a system administrator.  
    - `Project::APPROVED_STATUS` — When a project has been reviewed and approved by a system admninistrator. 
    - `Project::ACTIVE_STATUS` — When a project has been created in mediaflux. Also the rails Project has a `mediaflux_id` which can be queried in mediaflux.

## Consequences

- A system administrator has to take action in mediaflux and the rails application before a project can become active
- Approve and Active currently are distinct stages of a project, but may become the same in the future.
- There is currently no way to move backwards or downgrade a project from approved to pending or active back to approved.

