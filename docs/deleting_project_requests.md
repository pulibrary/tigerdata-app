# How to remove project requests in TigerData

Sometimes, new project requests in TigerData are made in error or as duplicates. When this happens, they should be removed to reduce clutter on the dashboard.

Right now, there is no way for admins to delete requests. The only way to do this is for a developer to intervene at the console. Per conversation with Research Computing admins and our Product Owner, New Project Requests deleted from the console are gone forever, and this is acceptable. No archive or backup is needed.

New Project Requests should only be deleted this way when the request to do some comes from Research Computing admins.

New Project Requests that are denied as part of the overall requesting workflow are handled in a different way.

## Process

- Log into the server and open a console.
- If you want to be able to see the requests, turn yourself into a sysadmin:
  ```bash
  u = User.find_by(email:$USER_EMAIL)
  u.sysadmin = true
  u.save!
  ```
- Delete requests as follows:
  ```bash
  req = NewProjectRequest.find($REQUEST_ID)
  req.destroy
  ```
- Remove your sysadmin role when you are done:
  ```bash
  u = User.find_by(email:$USER_EMAIL)
  u.sysadmin = true
  u.save!
  ```
