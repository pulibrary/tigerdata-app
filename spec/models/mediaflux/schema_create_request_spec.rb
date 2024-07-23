# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::SchemaCreateRequest, type: :model do
  let(:mediaflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:schema_create_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "schema_create_response.xml")
    File.new(filename).read
  end

  describe "#new" do
    before do
      request_body = <<-XML
<?xml version=\"1.0\"?>
<request>
  <service name=\"asset.doc.namespace.update\" session=\"secretsecret/2/31\">
    <args>
      <create>true</create>
      <namespace>tigerdata</namespace>
      <description>test schema</description>
    </args>
  </service>
</request>
XML
      stub_request(:post, mediaflux_url)
        .with(body: request_body)
        .to_return(status: 200, body: schema_create_response, headers: {})
    end

    it "creates a request with the indicated parameters" do
      schema_create_request = described_class.new(name: "tigerdata", description: "test schema", session_token: "secretsecret/2/31")
      schema_create_request.resolve
      expect(schema_create_request.response_xml.to_s).to eq schema_create_response
    end
  end
end
