# frozen_string_literal: true
namespace :load_users do
  desc "Load users from LDAP"
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

  task rdss_developers: [:environment] do
    system("rake load_users:default_users")
  end

  desc "Load RDSS developers and other required users from LDAP"
  task default_users: [:environment] do
    PrincetonUsers.load_default_users
    puts "RDSS developers and other required users loaded from LDAP"
  end
end
