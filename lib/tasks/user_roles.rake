# frozen_string_literal: true
namespace :user_roles do
  desc "Add developer role to a user based on their net ID (not available in production)"
  task :add_developer, [:uid] => [:environment] do |_, args|
    if Rails.env.development? || Rails.env.staging? || Rails.env.test?
      uid = args[:uid]
      u = User.find_by(uid: uid)
      u.developer = true
      u.save!
    end
  end

  desc "Remove developer role from a user based on their net ID (not available in production)"
  task :remove_developer, [:uid] => [:environment] do |_, args|
    if Rails.env.development? || Rails.env.staging? || Rails.env.test?
      uid = args[:uid]
      u = User.find_by(uid: uid)
      u.developer = false
      u.save!
    end
  end
end
