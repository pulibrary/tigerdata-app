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
end
