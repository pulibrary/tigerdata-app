# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectQuotaRefresh, type: :operation, integration: true do
  subject { described_class.new } # Or initialize with dependencies if any

  let!(:current_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:project) { test_project_from_path("/princeton/tigerdata/RDSS/Query/CProject") }
  let(:project_metadata) do
    project_metadata = ProjectMetadata.new(project)
    project_metadata.storage_capacity = { "size" => { "approved" => 12, "requested" => 24 },
                                          "unit" => { "approved" => "GB", "requested" => "GB" } }
    project_metadata.update_project
    project_metadata
  end

  describe "#call" do
    context "Success case" do
      it "creates updates the project with the more recent metadata" do
        date = DateTime.now
        allow(DateTime).to receive(:now).and_return(date)

        # the quota breakdown is empty before it is loaded
        expect(project_metadata.quota_breakdown).to eq({})

        result = described_class.new.call(current_user:, project_metadata:)
        expect(result).to be_success
        quota_info = result.value!
        expect(quota_info[:quota_allocation_human]).to eq("1 MB")
        expect(quota_info[:quota_allocation]).to eq(1000000)
        expect(quota_info[:quota_used]).to eq(181050)
        expect(quota_info[:project_files]).to eq(181050)
        expect(quota_info[:recycle_bin]).to eq(0)
        expect(quota_info[:old_versions]).to eq(0)

        # the quota breakdown is stored in the database
        project.reload
        expect(project.metadata_json["storage_capacity"]).to eq({ "size" => { "approved" => 1, "requested" => 24 },
                                                                  "unit" => { "approved" => "MB", "requested" => "GB" } })
        expect(project.metadata_json["quota_breakdown"]).to eq({ "old_versions" => 0, "old_versions_human" => "0 bytes",
                                                                 "project_files" => 181050, "project_files_human" => "181.05 KB",
                                                                 "quota_allocation" => 1000000, "quota_allocation_human" => "1 MB",
                                                                 "quota_used" => 181050, "quota_used_human" => "181.05 KB",
                                                                 "recycle_bin" => 0, "recycle_bin_human" => "0 bytes",
                                                                 "updated_from_mediaflux_on" => JSON.parse(date.to_json) })
        # make sure the data in the database is parsed by the model
        expect(ProjectMetadata.new(project).quota_breakdown).to eq(project.metadata_json["quota_breakdown"])
      end
    end

    context "Failure cases" do
      it "returns a failure for an error with Mediaflux" do
        quota_request = instance_double(Mediaflux::ProjectQuotaRequest, "error?" => true, response_error: "an error occured")
        allow(Mediaflux::ProjectQuotaRequest).to receive(:new).and_return(quota_request)
        result = described_class.new.call(current_user:, project_metadata:)
        expect(result).not_to be_success
        error_message = result.failure
        expect(error_message).to include("Error gathering quota information from mediaflux")
      end

      it "returns a failure if Mediaflux throws and exception" do
        instance_double(Mediaflux::ProjectQuotaRequest)
        allow(Mediaflux::ProjectQuotaRequest).to receive(:new).and_raise("error with call")
        result = described_class.new.call(current_user:, project_metadata:)
        expect(result).not_to be_success
        error_message = result.failure
        expect(error_message).to include("Error gathering quota information from mediaflux")
        expect(error_message).to include("error with call")
      end

      it "returns a failure if the project can not be updated" do
        project_metadata # make sure the project exists before the first save
        allow(project).to receive(:save!).and_raise("error during save")
        result = described_class.new.call(current_user:, project_metadata:)
        expect(result).not_to be_success
        error_message = result.failure
        expect(error_message).to include("Error updating project")
        expect(error_message).to include("error during save")
      end
    end
  end
end
