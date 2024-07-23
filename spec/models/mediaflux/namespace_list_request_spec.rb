# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceListRequest, type: :model do
  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:namespace_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "namespace_list_response.xml")
    File.new(filename).read
  end

  describe "#metadata" do
    before do
      stub_request(:post, mediflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.namespace.list\" session=\"secretsecret/2/31\">\n    "\
                    "<args>\n      <namespace>/td-demo-001</namespace>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: namespace_response, headers: {})
    end
    it "parses a metadata response" do
      namespace_request = described_class.new(session_token: "secretsecret/2/31", parent_namespace: "/td-demo-001")
      namespaces = namespace_request.namespaces
      expect(namespaces.count).to eq(3)
      expect(namespaces.first).to eq({ id: "1116", name: "pppl" })
      expect(WebMock).to have_requested(:post, mediflux_url)
    end
  end
end
