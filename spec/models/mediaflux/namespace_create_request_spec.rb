# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceCreateRequest, type: :model do
  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:namespace_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "generic_response.xml")
    File.new(filename).read
  end

  describe "#resolve" do
    # TODO: refactor the stub_mediaflux to connect to the real mediaflux
    #     1 Test: 22
    before do
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.namespace.create\" session=\"secretsecret/2/31\">\n    "\
                               "<args>\n      <namespace all=\"true\">abc</namespace>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: namespace_response, headers: {})
    end

    it "disconnects the session" do
      namespace_request = described_class.new(session_token: "secretsecret/2/31", namespace: "abc")
      namespace_request.resolve
      expect(WebMock).to have_requested(:post, mediflux_url)
    end
  end
end
