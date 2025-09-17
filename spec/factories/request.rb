# frozen_string_literal: true
FactoryBot.define do
  factory :request, class: "Request" do
    quota { "custom" }
    storage_size { 2 }
    storage_unit { "TB" }
    approved_quota { "custom" }
    approved_storage_size { "10" }
    approved_storage_unit { "GB" }
    project_title { "Test request" }
  end

  factory :request_project, class: "Request" do
    quota { "custom" }
    data_sponsor { "tigerdatatester" }  # Must be a valid netid/uid
    data_manager { "tigerdatatester" }  # Must be a valid netid/uid
    user_roles { [] }
    storage_size { 2 }
    storage_unit { "TB" }
    approved_quota { "custom" }
    approved_storage_size { "500" }
    approved_storage_unit { "GB" }
    project_title { FFaker::Movie.title }
    departments { [{name: "RDSS"}, {name: "RC"}] }
    description { "a random description" }
    project_folder { random_project_directory }
  end
end
