# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectMetadata, type: :model do
  let(:researcher_user) { FactoryBot.create(:user, uid: "hc1234") }
  let(:project) { Project.new(metadata_json: metadata_json) }
  let(:project_metadata) { described_class.new(project) }
  let(:data_security_level) { nil } # no default is set for security level
  let(:metadata_json) do
    {
      data_sponsor: "abc",
      data_manager: "def",
      departments: "dep",
      project_directory: " dir ",
      title: "title abc",
      description: "description 123",
      status: "approved",
      data_security_level: data_security_level
    }.with_indifferent_access
  end

  let(:default_quota_allocation) do
    { requested: 500, approved: nil }.with_indifferent_access
  end

  let(:default_storage_performance_expectations) do
    { requested: "Standard", approved: nil }.with_indifferent_access
  end

  let(:default_project_purpose) { "Research" }

  describe "#initialize_from_hash" do
    it "parses basic metadata" do
      expect(project_metadata.data_sponsor).to eq("abc")
      expect(project_metadata.data_manager).to eq("def")
      expect(project_metadata.departments).to eq("dep")
      expect(project_metadata.project_directory).to eq("dir")
      expect(project_metadata.title).to eq("title abc")
      expect(project_metadata.description).to eq("description 123")
      expect(project_metadata.status).to eq("approved")
      expect(project_metadata.data_security_level).to be_nil
    end

    it "overwrites default values when given" do
      metadata_json[:project_purpose] = "Not research"
      expect(project_metadata.project_purpose).to eq "Not research"
    end

    context "when security level is provided" do
      let(:data_security_level) { 3 }

      it "sets the data security level" do
        expect(project_metadata.data_security_level).to eq(3)
      end
    end
  end

  describe "#safe_directory" do
    it "handles nil values" do
      expect(described_class.safe_directory(nil)).to eq ""
    end

    it "honors dashes and underscores" do
      expect(described_class.safe_directory("abc_123")).to eq "abc_123"
      expect(described_class.safe_directory("abc-456")).to eq "abc-456"
    end

    it "replaces unexpected characters with dashes" do
      expect(described_class.safe_directory("hello#world{x}")).to eq "hello-world-x-"
    end
  end

  describe ".default_storage_unit" do
    it "returns the default storage unit of KB" do
      expect(described_class.default_storage_unit).to eq("KB")
    end
  end

  describe ".default_storage_usage" do
    it "returns the default storage usage of 0 units" do
      expect(described_class.default_storage_usage).to eq("0 KB")
    end
  end

  describe "as_json" do
    it "does not show the project" do
      expect(project_metadata.as_json).to eq({ "asset_count" => 0, "data_manager" => "def", "data_security_level" => nil, "data_sponsor" => "abc", "request_metadata" => nil,
                                               "data_use_agreement" => "No", "departments" => "dep", "description" => "description 123", "globus_request" => "No",
                                               "hpc" => "No", "number_of_files" => "Less than 10,000", "project_directory" => "dir", "project_id" => "DOI-NOT-MINTED",
                                               "project_purpose" => nil, "project_visibility" => "Restricted", "provisional" => false, "quota_allocation" => "0 GB",
                                               "quota_allocation_raw" => 0, "resource_type" => "TigerData Project", "schema_version" => "0.6.1", "smb_request" => "No",
                                               "status" => "approved", "storage_usage" => "0 KB", "storage_usage_raw" => 0, "submission" => {}, "title" => "title abc" })
    end
  end

  describe "#update_with_mediaflux_data" do
    let(:sponsor_and_data_manager) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
    let(:rw_user) { FactoryBot.create(:user, uid: "libtigerdatadev") }
    let(:user_roles) { [{ uid: rw_user.uid, name: rw_user.display_name }, { uid: rw_user.uid, name: rw_user.display_name, read_only: false }] }
    let(:project) do
      request = FactoryBot.create(:request_project, number_of_files: "lots", user_roles:)
      request.approve(sponsor_and_data_manager)
    end
    let(:project_request_metadata) { project.metadata_json }

    it "stores data from submission and pulls in and saves data from mediaflux" do
      project_request_metadata
      expect(project_request_metadata["quota_allocation"]).to eq("0 GB")
      project_metadata = ProjectMetadata.new(project)
      expect(project_metadata.request_metadata).to be_nil
      expect(project_metadata.title).to eq(project.metadata_json["title"])
      expect(project_metadata.quota_allocation).to eq("0 GB")
      expect(project_metadata.status).to eq("active")
      expect(project_metadata.data_user_read_only).to eq(["libtigerdatadev"])
      expect(project_metadata.number_of_files).to eq("lots")
      expect(project_metadata.storage_capacity).to eq({ "size" => { "approved" => "500.0", "requested" => "2.0" }, "unit" => { "approved" => "GB", "requested" => "TB" } })
      expect(project_metadata.updated_from_mediaflux_on).to be_nil
      project_metadata.update_with_mediaflux_data(session_id: sponsor_and_data_manager.mediaflux_session)

      project_metadata = ProjectMetadata.new(project.reload) # reload and recreate so we are sure this is stored in the database

      # the request metadata is present and the project metadata include information from mediaflux
      expect(project_metadata.updated_from_mediaflux_on).not_to be_nil
      expect(project_metadata.quota_allocation).to eq("500 GB") # the actual alloction
      expect(project_metadata.request_metadata["quota_allocation"]).to eq("0 GB") # our original default
      expect(project_metadata.storage_usage).to eq("0 bytes")

      expect(project_metadata.title).to eq(project.metadata_json["title"])

      # Since the project was not updated from mediaflux before now the request_metadata does not have that key
      expect(project.metadata_json.keys - project_metadata.request_metadata.keys).to eq(["updated_by", "updated_from_mediaflux_on"])

      # project metadata_json and project_metadata should have the same data stored
      expect(project.metadata_json.keys - project_metadata.as_json.keys).to eq([])
      expect(project_metadata.as_json.keys - project.metadata_json.keys).to eq([])
      expect(JSON.parse(project_metadata.to_json)).to eq(JSON.parse(project.metadata_json.to_json))

      # data from the request remains even after we load data from mediaflux that does not have that information
      expect(project_metadata.request_metadata["number_of_files"]).to eq("lots") # data from the request not stored in mediaflux
      expect(project_metadata.number_of_files).to eq("lots")
      expect(project_metadata.request_metadata["data_user_read_only"]).to eq(["libtigerdatadev"]) # data from the request not stored in mediaflux
      expect(project_metadata.data_user_read_only).to eq(["libtigerdatadev"])
      expect(project_metadata.data_user_read_only).to eq(["libtigerdatadev"])
      expect(project_metadata.request_metadata["data_user_read_write"]).to eq(["libtigerdatadev"]) # data from the request not stored in mediaflux
      expect(project_metadata.data_user_read_write).to eq(["libtigerdatadev"])
      expect(project_metadata.data_user_read_write).to eq(["libtigerdatadev"])
      expect(project_metadata.request_metadata["status"]).to eq("active") # data from the request not stored in mediaflux
      expect(project_metadata.status).to eq("active")
      expect(project_metadata.storage_capacity).to eq({ "size" => { "approved" => "500.0", "requested" => "2.0" }, "unit" => { "approved" => "GB", "requested" => "TB" } })
    end
  end
end
