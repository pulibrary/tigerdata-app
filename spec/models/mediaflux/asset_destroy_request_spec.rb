# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::AssetDestroyRequest, type: :model do
  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }
  let(:metdata_response) do
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<response>\n  <reply type=\"result\">\n    <result/>\n  </reply>\n</response>\n"
  end

  describe "#result" do
    before do
      stub_request(:post, mediflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.destroy\" session=\"secretsecret/2/31\">\n    <args>\n"\
        "      <id>1065</id>\n      <members>true</members>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: metdata_response, headers: {})
    end
    it "parses the result" do
      metadata_request = described_class.new(session_token: "secretsecret/2/31", collection: 1065, members: true)
      expect(metadata_request.error?).to be_falsey
      expect(WebMock).to have_requested(:post, mediflux_url)
    end
  end
end
