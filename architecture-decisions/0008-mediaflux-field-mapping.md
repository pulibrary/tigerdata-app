# 8. Schema mapping 0.6.1 from Mediaflux provisional projects

Date: 2024-10-15

## Status
 In discussion


## Context

 - There are provisional projects that exist in Mediaflux that do not exist in the front end application.  We will create a report of information from Mediaflux and then read that report in to create projects in the front end.

## Decision

- Schema Fields to Mediaflux asset data:
    - project_directory => asset/meta/tigerdata:project/ProjectDirectory (note this could also be asset/path)
    - title => asset/meta/tigerdata:project/Title
    - status => "published"
    - data_sponsor => asset/meta/tigerdata:project/DataSponsor
    - data_manager => asset/meta/tigerdata:project/DataManager
    - data_users => asset/meta/tigerdata:project/DataUser [list] Assume all data users are read/write
    - departments => asset/meta/tigerdata:project/Department
    - created_on => asset/ctime
    - created_by => asset/creator
    - project_id => asset/meta/tigerdata:project/ProjectID
    - storage => asset/collection/quota/allocation
    - storage_performance => asset/collection/store (assume there will be a mapping between store and performance)
    - project_purpose => "Research"
    - requested_by => asset/meta/tigerdata:project/DataSponsor
    - requested_date =>  asset/ctime
    - approved_by => asset/creator
    - approved_date => asset/ctime
    - mediaflux_id => asset/id

- Mediaflux fields:
    - asset/id
    - asset/path
    - asset/ctime
    - asset/creator
    - asset/collection/quota/allocation
    - asset/collection/store
    - asset/meta/tigerdata:project/ProjectDirectory
    - asset/meta/tigerdata:project/Title
    - asset/meta/tigerdata:project/DataSponsor
    - asset/meta/tigerdata:project/DataManager
    - asset/meta/tigerdata:project/DataUser
    - asset/meta/tigerdata:project/Department
    - asset/meta/tigerdata:project/ProjectID

## Consequences

- Provisional projects will have some metadata that is not entirely correct, but matches with mediaflux data
- Projects in Mediaflux can be seen in the front end

