# frozen_string_literal: true
namespace :load_users do
  desc "Load in users from the registration list"
  task from_registration_list: :environment do
    User.load_registration_list
  end

  desc "Load user from ldap"
  task from_ldap: :environment do
    count_before = User.count
    PrincetonUsers.create_users_from_ldap
    count_after = User.count
    puts "Create #{count_after - count_before} users from ldap"
  end
end
