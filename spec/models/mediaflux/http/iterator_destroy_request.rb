# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::IteratorDestroyRequest, type: :model do
  let(:mediaflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  describe "#result" do
    let(:query_response) do
      filename = Rails.root.join("spec", "fixtures", "files", "iterator_response_get_values.xml")
      File.new(filename).read
    end

    before do
      stub_request(:post, mediaflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query.iterator.destroy\" session=\"secretsecret/2/31\">\n    " \
        "<args>\n      <id>123</id>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: "query_response", headers: {})
    end

    it "destroys an iterator" do
      query_request = described_class.new(session_token: "secretsecret/2/31", iterator: "123")
      expect(query_request.result).to eq ""
      expect(WebMock).to have_requested(:post, mediaflux_url)
    end
  end
end
