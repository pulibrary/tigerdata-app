# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::AssetMetadataRequest, connect_to_mediaflux: true, type: :model do
  let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }
  let(:user) { FactoryBot.create(:user) }
  let(:approved_project) { FactoryBot.create(:approved_project) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n" }

  let(:metdata_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_get_response.xml")
    File.new(filename).read
  end

  describe "#metadata" do
    before do
      approved_project.mediaflux_id = nil
      @mediaflux_id = ProjectMediaflux.create!(project: approved_project, user:)
      asset_req = Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: @mediaflux_id)
      asset_response = asset_req.response_body.split("<id>")[1]
      @asset_id = asset_response.split("<")[0].to_i
      asset_req.resolve
    end
    it "parses a metadata response" do
      metadata_request = described_class.new(session_token: user.mediaflux_session, id: @asset_id)
      metadata = metadata_request.metadata
      expect(metadata[:id]).to eq(@asset_id.to_s)
      expect(metadata[:creator]).to eq("manager")
      expect(metadata[:description]).to eq("")
      expect(metadata[:collection]).to be_falsey
      expect(metadata[:path]).to eq("/td-test-001/test/tigerdata/big-data/__asset_id__#{@asset_id}")
      expect(metadata[:type]).to eq("")
      expect(metadata[:size]).to be nil
    end

    context "A collection" do
      it "parses a metadata response" do
        metadata_request = described_class.new(session_token: user.mediaflux_session, id: @mediaflux_id)
        metadata = metadata_request.metadata
        expect(metadata[:creator]).to eq("manager")
        expect(metadata[:description]).to eq("a random description")
        expect(metadata[:collection]).to be_truthy
        expect(metadata[:path]).to eq("/td-test-001/test/tigerdata/big-data")
        expect(metadata[:type]).to eq("application/arc-asset-collection")
        expect(metadata[:size]).to eq("")
        expect(metadata[:total_file_count]).to eq("")
        expect(metadata[:quota_allocation]).to eq("500 GB")
        expect(metadata[:project_directory]).to eq("/td-test-001/test/tigerdataNS/big-data")
        expect(metadata[:project_id]).to eq("10.34770/tbd")
      end
    end

    context "actual mediaflux connection" do
      let(:current_user) { FactoryBot.create(:user, uid: "hc1234") }
      let(:valid_project) { FactoryBot.create(:project_with_dynamic_directory, project_id: "10.34770/tbd") }
      let(:session_token) { current_user.mediaflux_session }

      before do
        # create a project in mediaflux
        valid_project.mediaflux_id = ProjectMediaflux.create!(project: valid_project, user: current_user)
        ProjectAccumulator.new(project: valid_project, session_id: session_token).create!
      end

      it "parses the resonse" do
        metadata_request = described_class.new(session_token: session_token, id: valid_project.mediaflux_id)
        metadata = metadata_request.metadata
        expect(metadata[:id]).to eq(valid_project.mediaflux_id.to_s)
        expect(metadata[:creator]).to eq("manager")
        expect(metadata[:description]).to eq("a random description")
        expect(metadata[:collection]).to be_truthy
        expect(metadata[:path].include?(valid_project.metadata_json["project_directory"])).to be_truthy
        expect(metadata[:type]).to eq("application/arc-asset-collection")
        expect(metadata[:size]).to eq("0 bytes")
        expect(metadata[:total_file_count]).to eq("0")
        expect(metadata[:quota_allocation]).to eq("500 GB")
        expect(metadata[:project_id]).to eq("10.34770/tbd")
        expect(metadata[:project_directory]).to eq(valid_project.project_directory)
        expect(metadata[:created_by]).to eq(valid_project.metadata[:created_by])
        expect(metadata[:updated_by]).to be_blank # we have not updted the project so no updated by is available
      end
    end
  end
end
