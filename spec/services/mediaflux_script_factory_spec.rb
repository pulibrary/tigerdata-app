# frozen_string_literal: true
require "rails_helper"

describe MediafluxScriptFactory do
  let!(:hc_user) { FactoryBot.create(:project_sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  let(:project) { FactoryBot.create(:approved_project) }
  subject(:mediaflux_service) { described_class.new(project: project) }

  describe "#aterm_script" do
    let(:output) { mediaflux_service.aterm_script }

    it "generates the Mediaflux API script for creating a project" do
      expect(output).to include(":pid path=#{mediaflux_service.project_parent_path}")
      expect(output).to include(":namespace #{mediaflux_service.project_namespace}")
      expect(output).to include(":name #{project.project_directory_short}")
      # Metadata
      expect(output).to include(":ProjectDirectory \"#{project.metadata_model.project_directory}\"")
      expect(output).to include(":Title \"#{project.metadata_model.title}\"")
      expect(output).to include(":Description \"#{project.metadata_model.description}\"")
      expect(output).to include(":Status \"#{project.metadata_model.status}\"")
      expect(output).to include(":DataSponsor \"#{project.metadata_model.data_sponsor}\"")
      expect(output).to include(":DataManager \"#{project.metadata_model.data_manager}\"")
      expect(output).to include(":CreatedBy \"#{project.metadata_model.created_by}\"")
      expect(output).to include(":ProjectID \"#{project.metadata_model.project_id}\"")
      expect(output).to include(":StorageCapacity < :Size #{project.metadata_model.storage_capacity[:size][:requested]}")
      expect(output).to include(":Unit \"#{project.metadata_model.storage_capacity[:unit][:requested]}\"")
      expect(output).to include(":Performance \"#{project.metadata_model.storage_performance_expectations[:requested]}\"")
      expect(output).to include(":ProjectPurpose \"#{project.metadata_model.project_purpose}\"")
      expect(output).to include(":SchemaVersion \"#{project.metadata_model.schema_version}\"")
      # Quota
      expect(output).to include(":quota")
      expect(output).to include(":description \"Project Quota\"")
      # Accumulators
      expect(output).to include("asset.collection.accumulator.add")
      expect(output).to include(":name #{project.project_directory_short}-count")
      expect(output).to include(":name #{project.project_directory_short}-size")
    end
  end
end
