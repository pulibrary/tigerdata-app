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

    ##
    # A user who has the data sponsor role
    factory :data_sponsor do
      after :create do |user|
        user.add_role User::DATA_SPONSOR
      end
    end

    ##
    # A user who has the data manager role
    factory :data_manager do
      after :create do |user|
        user.add_role User::DATA_MANAGER
      end
    end

    ##
    # A user who has the data user role
    factory :data_user do
      after :create do |user|
        user.add_role User::DATA_USER
      end
    end

    ##
    # A user who is allowed to administer mediaflux
    factory :mediaflux_admin do
      after :create do |user|
        user.add_role User::MEDIAFLUX_ADMIN
      end
    end
  end
end
