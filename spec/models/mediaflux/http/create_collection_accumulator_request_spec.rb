# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::CreateCollectionAccumulatorRequest, type: :model do
  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:create_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_collection_accumulator_add_response.xml")
    File.new(filename).read
  end

  describe "#resolve" do
    before do
      stub_request(:post, mediflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.collection.accumulator.add\" session=\"secretsecret/2/31\">\n"\
                    "    <args>\n      <id>1234</id>\n      <cascade>true</cascade>\n      <accumulator>\n        <name>testasset</name>\n        <type>collection.asset.count</type>\n"\
                    "      </accumulator>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: create_response, headers: {})
    end

    it "parses a response" do
      create_request = described_class.new(session_token: "secretsecret/2/31", name: "testasset", collection: "1234", type: "collection.asset.count")
      response = create_request.resolve
      expect(response.code).to eq("200")
      expect(a_request(:post, mediflux_url).with do |req|
        req.body.include?("<name>testasset</name>")
      end).to have_been_made
    end
  end
end
