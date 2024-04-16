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
      project_id { "10.34770/tbd" }
      status { "pending" }
      storage_capacity { "500 GB" }
      storage_performance { "standard" }
      project_purpose { "research" }
      directory { "big-data" }
    end
    mediaflux_id { nil }
    metadata do
      {
        data_sponsor: data_sponsor,
        data_manager: data_manager,
        data_user_read_only: data_user_read_only,
        data_user_read_write: data_user_read_write,
        departments: ["RDSS", "PRDS"],
        directory: directory,
        title: title,
        description: "a random description",
        created_on: created_on,
        created_by: FactoryBot.create(:user).uid,
        updated_on: updated_on,
        updated_by: FactoryBot.create(:user).uid,
        project_id: project_id,
        status: status,
        storage_capacity_requested: storage_capacity,
        storage_performance_expectations_requested: storage_performance,
        project_purpose: project_purpose
      }
    end
  end
end
