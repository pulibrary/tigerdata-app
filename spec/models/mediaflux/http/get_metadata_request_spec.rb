# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::GetMetadataRequest, type: :model do
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
        expect(WebMock).to have_requested(:post, mediflux_url)
      end
    end
  end
end
