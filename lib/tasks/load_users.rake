# frozen_string_literal: true
namespace :load_users do
    desc "Load in users from the registration list"
    task from_registration_list: :environment do
        User.load_registration_list
    end
end