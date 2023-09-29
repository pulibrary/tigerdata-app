# User Roles
Users will have one or more roles in the system.  Eventually these roles will be defined in the system by administrators or project sponsors.  For the moment the roles are defined by a rake task.

## Defined Roles
   - Project Sponsor - A user than can create new projects

## Default Roles Rake Task
   To create or update users with the default roles run
   ```
   bundle exec rake roles:default_sponsors
   ```
   To add additional users to the project sponsor role edit `config/default_sponsors.yml` and add additional netids to the correct environments

## Adding a role to a user
   roles can be added to any user in the rails console.  Assuming you have set the variable netid to the user's netid (`netid="cac9"`) the following code can be utilized to add the project sponsor role to the user.
   ```
   user = User.find_by(uid: netid)
   user.add_role User::PROJECT_SPONSOR
   ```
