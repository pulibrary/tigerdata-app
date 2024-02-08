# frozen_string_literal: true

FactoryBot.define do
  factory :user, class: "User" do
    uid { FFaker::InternetSE.unique.login_user_name }
    display_name { FFaker::Name.name }
    given_name { display_name.split(" ").first }
    family_name { display_name.split(" ").last }
    provider { :cas }
    email { "#{uid}@example.com" }
    eligible_sponsor { false }
    eligible_manager { false }

    ##
    # A user who is allowed to sponsor a project
    factory :project_sponsor do
      eligible_sponsor { true }
    end

    ##
    # A user who is allowed to manage a project
    factory :project_manager do
      eligible_manager { true }
    end
  end
end
