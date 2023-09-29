# frozen_string_literal: true
namespace :roles do
  desc "Create or update the system users for the project sponsor role"
  task default_sponsors: :environment do
    config.default_sponsors.each do |sponsor|
      user = User.find_by(uid: sponsor)
      if user.nil?
        user = User.create(uid: sponsor, provider: "cas", emai: "#{sponsor}@princeton.edu")
      end
      unless user.has_role? User::PROJECT_SPONSOR
        user.add_role User::PROJECT_SPONSOR
      end
    end
  end
end
