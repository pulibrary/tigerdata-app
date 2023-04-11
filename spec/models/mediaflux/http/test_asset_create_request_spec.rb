# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::TestAssetCreateRequest, type: :model do
  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:test_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "generic_response.xml")
    File.new(filename).read
  end

  describe "#resolve" do
    before do
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.test.create\" session=\"secretsecret/2/31\">\n    "\
                     "<args>\n      <pid>123</pid>\n      <nb>20</nb>\n      <base-name>abc</base-name>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: test_response, headers: {})
    end

    it "disconnects the session" do
      namespace_request = described_class.new(session_token: "secretsecret/2/31", parent_id: 123, count: 20, pattern: "abc")
      namespace_request.resolve
      expect(WebMock).to have_requested(:post, mediflux_url)
    end
  end
end
