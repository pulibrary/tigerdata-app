# frozen_string_literal: true
namespace :load_users do
  desc "Load user from ldap"
  task from_ldap: :environment do
    count_before = User.count
    PrincetonUsers.create_users_from_ldap
    count_after = User.count
    puts "Create #{count_after - count_before} users from ldap"
  end

  desc "Load a single user based on their net ID"
  task :load_single_user, [:uid] => [:environment] do |_, args|
    uid = args[:uid]
    PrincetonUsers.create_user_from_ldap_by_uid(uid)
  end

  desc "Load RDSS developers from LDAP"
  task rdss_developers: [:environment] do
    PrincetonUsers.load_rdss_developers
    puts "RDSS developers loaded from LDAP"
  end
end
