# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::RangeQueryRequest, type: :model do
  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:query_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_query_range_size_response.xml")
    File.new(filename).read
  end

  before do
    stub_request(:post, mediflux_url)
      .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query\" session=\"secretsecret/2/31\">\n    "\
                  "<args>\n      <collection>1234</collection>\n      <action>range</action>\n      <xpath>content/size</xpath>\n    </args>\n  </service>\n</request>\n")
      .to_return(status: 200, body: query_response, headers: {})
  end

  describe "#minimum" do
    it "returns the minimum value" do
      query_request = described_class.new(session_token: "secretsecret/2/31", xpath: "content/size", collection: 1234)
      expect(query_request.minimum).to eq(100)
      expect(WebMock).to have_requested(:post, mediflux_url)
    end
  end

  describe "#maximum" do
    it "returns the maximum value" do
      query_request = described_class.new(session_token: "secretsecret/2/31", xpath: "content/size", collection: 1234)
      expect(query_request.maximum).to eq(55_000)
      expect(WebMock).to have_requested(:post, mediflux_url)
    end
  end
end
