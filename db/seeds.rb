# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).


Role.create(name: "Data Sponsor", description_md:"
- The person bearing primary responsibility for a project
- Must be eligible to be a Principal Investigator")

Role.create(name: "Data Manager", description_md:"
- The person who manages day-to-day project activities
- Must be trained by the Research Data Service")

Role.create(name: "Data User", description_md:"
- A person who accesses data/metadata in a project
- Must be an affiliate of Princeton University")