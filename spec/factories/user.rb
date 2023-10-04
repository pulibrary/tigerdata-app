# frozen_string_literal: true

FactoryBot.define do
  factory :user, class: "User" do
    uid { FFaker::InternetSE.unique.login_user_name }
    display_name { FFaker::Name.name }
    given_name { display_name.split(" ").first }
    family_name { display_name.split(" ").last }
    provider { :cas }
    email { "#{uid}@example.com" }

    ##
    # A user who is allowed to sponsor a project
    factory :project_sponsor do
      after :create do |user|
        user.add_role User::PROJECT_SPONSOR
      end
    end
  end
end
