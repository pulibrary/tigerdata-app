# frozen_string_literal: true
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
set :output, "/opt/tigerdata/shared/cron.log"

every 1.day, roles: [:rake] do
  rake "file_inventory:clean_up"
end

every :day, at: "01:00am", roles: [:rake] do
  rake "load_users:from_ldap"
end

every 1.day, roles: [:rake] do
  rake "request:clean_up"
end
