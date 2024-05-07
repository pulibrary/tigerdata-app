# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::AssetMetadataRequest, type: :model do
  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:metdata_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_get_response.xml")
    File.new(filename).read
  end

  describe "#metadata" do
    before do
      stub_request(:post, mediflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.get\" session=\"secretsecret/2/31\">\n    <args>\n      <id>1065</id>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: metdata_response, headers: {})
    end
    it "parses a metadata response" do
      metadata_request = described_class.new(session_token: "secretsecret/2/31", id: 1065)
      metadata = metadata_request.metadata
      expect(metadata[:id]).to eq("1065")
      expect(metadata[:creator]).to eq("manager")
      expect(metadata[:description]).to eq("")
      expect(metadata[:collection]).to be_falsey
      expect(metadata[:path]).to eq("/td-test-001/collection-96-55948/file-96-57045")
      expect(metadata[:type]).to eq("content/unknown")
      expect(metadata[:size]).to be nil
      expect(WebMock).to have_requested(:post, mediflux_url)
    end

    context "A collection" do
      let(:metdata_response) do
        filename = Rails.root.join("spec", "fixtures", "files", "collection_asset_get_response.xml")
        File.new(filename).read
      end

      it "parses a metadata response" do
        metadata_request = described_class.new(session_token: "secretsecret/2/31", id: 1065)
        metadata = metadata_request.metadata
        expect(metadata[:id]).to eq("1065")
        expect(metadata[:creator]).to eq("manager")
        expect(metadata[:description]).to eq("")
        expect(metadata[:collection]).to be_truthy
        expect(metadata[:path]).to eq("/td-test-001/collection-96-58278")
        expect(metadata[:type]).to eq("application/arc-asset-collection")
        expect(metadata[:size]).to eq("6 KB")
        expect(metadata[:total_file_count]).to eq("60")
        expect(metadata[:quota_allocation]).to eq("300 GB")
        expect(metadata[:project_directory]).to eq("accum-07576")
        expect(metadata[:project_id]).to eq("doi-not-generated")
        expect(WebMock).to have_requested(:post, mediflux_url)
      end
    end

    context "actual mediaflux connection", connect_to_mediaflux: true do
      let(:current_user) { FactoryBot.create(:user, uid: "hc1234") }
      let(:valid_project) { FactoryBot.create(:project_with_dynamic_directory, project_id: "10.34770/tbd") }
      let(:session_token) { current_user.mediaflux_session }

      before do
        # create a project in mediaflux
        valid_project.mediaflux_id = ProjectMediaflux.create!(project: valid_project, session_id: session_token)
      end

      after do
        Mediaflux::Http::AssetDestroyRequest.new(session_token: current_user.mediaflux_session, collection: valid_project.mediaflux_id, members: true).resolve
      end

      it "parses the resonse" do
        metadata_request = described_class.new(session_token: session_token, id: valid_project.mediaflux_id)
        metadata = metadata_request.metadata
        expect(metadata[:id]).to eq(valid_project.mediaflux_id.to_s)
        expect(metadata[:creator]).to eq("manager")
        expect(metadata[:description]).to eq("")
        expect(metadata[:collection]).to be_truthy
        expect(metadata[:path].include?(valid_project.metadata_json["project_directory"])).to be_truthy
        expect(metadata[:type]).to eq("application/arc-asset-collection")
        expect(metadata[:size]).to eq("") # accumulators are not added to project when created
        expect(metadata[:total_file_count]).to eq("") # accumulators are not added to project when created
        expect(metadata[:quota_allocation]).to eq("") # quotas are not added to project when created
        expect(metadata[:project_id]).to eq("10.34770/tbd")
        expect(metadata[:project_directory]).to eq(valid_project.metadata_json["project_directory"])
      end
    end
  end
end
