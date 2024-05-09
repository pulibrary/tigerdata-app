# frozen_string_literal: true

FactoryBot.define do
  factory :project, class: "Project" do
    transient do
      data_sponsor { FactoryBot.create(:project_sponsor).uid }
      data_manager { FactoryBot.create(:data_manager).uid }
      data_user_read_only { [] }
      data_user_read_write { [] }
      title { FFaker::Movie.title }
      created_on { Time.current.in_time_zone("America/New_York").iso8601 }
      updated_on { Time.current.in_time_zone("America/New_York").iso8601 }
      project_id { "" }
      status { "pending" }
      storage_capacity { { size: { requested: 500 }, unit: { requested: "GB" } } }
      storage_performance { { requested: "standard" } }
      project_purpose { "research" }
      project_directory { "big-data" }
      schema_version { ::TigerdataSchema::SCHEMA_VERSION }
    end
    mediaflux_id { nil }
    metadata do
      {
        data_sponsor: data_sponsor,
        data_manager: data_manager,
        data_user_read_only: data_user_read_only,
        data_user_read_write: data_user_read_write,
        departments: ["RDSS", "PRDS"],
        project_directory: project_directory,
        title: title,
        description: "a random description",
        created_on: created_on,
        created_by: FactoryBot.create(:user).uid,
        updated_on: updated_on,
        updated_by: FactoryBot.create(:user).uid,
        project_id: project_id,
        status: status,
        storage_capacity: storage_capacity,
        storage_performance_expectations: storage_performance,
        project_purpose: project_purpose,
        schema_version: schema_version
      }
    end
    factory :project_with_doi, class: "Project" do
      sequence :project_id do |n|
        "doi:000000#{n}/00000000000#{n}"
      end
    end
    factory :project_with_dynamic_directory, class: "Project" do
      transient do
        sequence :project_directory do |n|
          "#{FFaker::Food.fruit}#{n}"
        end
      end
    end
  end
end
