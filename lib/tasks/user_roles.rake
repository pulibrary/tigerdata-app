# frozen_string_literal: true
namespace :user_roles do
  desc "Add superuser role to a user based on their net ID (not available in production)"
  task :add_superuser, [:uid] => [:environment] do |_, args|
    if Rails.env.development? || Rails.env.staging? || Rails.env.test?
      uid = args[:uid]
      u = User.find_by(uid: uid)
      u.superuser = true
      u.save!
    end
  end

  desc "Remove superuser role from a user based on their net ID (not available in production)"
  task :remove_superuser, [:uid] => [:environment] do |_, args|
    if Rails.env.development? || Rails.env.staging? || Rails.env.test?
      uid = args[:uid]
      u = User.find_by(uid: uid)
      u.superuser = false
      u.save!
    end
  end
end
