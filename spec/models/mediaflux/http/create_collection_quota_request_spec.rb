# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::CreateCollectionQuotaRequest, type: :model do
  let(:mediaflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:create_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "create_collection_quota_response.xml")
    File.new(filename).read
  end

  describe "#resolve" do
    before do
      stub_request(:post, mediaflux_url)
      .with(
        body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.collection.quota.set\" session=\"fake_session\">\n    <args>\n      <id>1304</id>\n      <quota>\n        <allocation>1 MB</allocation>\n        <description>1 MB quota for 1304</description>\n      </quota>\n    </args>\n  </service>\n</request>\n",
        headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Connection'=>'keep-alive',
        'Content-Type'=>'text/xml; charset=utf-8',
        'Keep-Alive'=>'30',
        'User-Agent'=>'Ruby'
        }).
      to_return(status: 200, body: "", headers: {})
    end

    it "parses a response" do
      create_request = described_class.new(session_token: "fake_session", collection: "1304", allocation: "1 MB")
      response = create_request.resolve
      expect(response.code).to eq("200")
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<description>1 MB quota for 1304</description>")
      end).to have_been_made
    end
  end
end
