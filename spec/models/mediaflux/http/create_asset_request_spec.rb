# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::CreateAssetRequest, type: :model do
  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:create_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_create_response.xml")
    File.new(filename).read
  end

  describe "#id" do
    before do
      stub_request(:post, mediflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.create\" session=\"secretsecret/2/31\">\n    "\
                    "<args>\n      <name>testasset</name>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: create_response, headers: {})
    end

    it "parses a metdata response" do
      create_request = described_class.new(session_token: "secretsecret/2/31", name: "testasset", collection: false)
      expect(create_request.id).to eq("1068")
      expect(WebMock).to have_requested(:post, mediflux_url)
    end

    context "A collection" do
      before do
        stub_request(:post, mediflux_url)
          .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.create\" session=\"secretsecret/2/31\">\n    "\
                      "<args>\n      <name>testasset</name>\n      <collection contained-asset-index=\"true\" unique-name-index=\"true\">true</collection>\n"\
                      "      <type>application/arc-asset-collection</type>\n    </args>\n  </service>\n</request>\n")
          .to_return(status: 200, body: create_response, headers: {})
      end

      it "parses a metdata response" do
        create_request = described_class.new(session_token: "secretsecret/2/31", name: "testasset", collection: true)
        expect(create_request.id).to eq("1068")
        expect(WebMock).to have_requested(:post, mediflux_url)
      end
    end
  end
end
