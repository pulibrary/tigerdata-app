# frozen_string_literal: true
namespace :load_users do
  desc "Load user from ldap"
  task from_ldap: :environment do
    count_before = User.count
    PrincetonUsers.create_users_from_ldap
    count_after = User.count
    puts "Create #{count_after - count_before} users from ldap"
  end
end
