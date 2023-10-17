# frozen_string_literal: true
namespace :roles do
  desc "Create or update the system users for the project sponsor role"
  task default_sponsors: :environment do
    Rails.application.config.default_sponsors.each do |sponsor|
      user = User.find_by(uid: sponsor)
      if user.nil?
        user = User.create(uid: sponsor, provider: "cas", email: "#{sponsor}@princeton.edu")
      end
      unless user.has_role? User::PROJECT_SPONSOR
        user.add_role User::PROJECT_SPONSOR
      end
    end
  end

  desc "Create or update the system users for the mediaflux admin role"
  task default_mediaflux_admins: :environment do
    Rails.application.config.default_mediaflux_admins.each do |mediaflux_admin|
      user = User.find_by(uid: mediaflux_admin)
      if user.nil?
        user = User.create(uid: mediaflux_admin, provider: "cas", email: "#{mediaflux_admin}@princeton.edu")
      end
      unless user.has_role? User::MEDIAFLUX_ADMIN
        user.add_role User::MEDIAFLUX_ADMIN
      end
    end
  end
end
