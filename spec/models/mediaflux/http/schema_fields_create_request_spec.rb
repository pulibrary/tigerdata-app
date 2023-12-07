# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::SchemaFieldsCreateRequest, type: :model do
  let(:mediaflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:schema_fields_create_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "schema_fields_create_response.xml")
    File.new(filename).read
  end

  let(:required_indexed_field) { { name: "code", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "desc" } }
  let(:required_not_indexed_field) { { name: "title", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "desc" } }
  let(:optional_field) { { name: "data_users_rw", type: "string", index: false, "min-occurs" => 0, label: "desc" } }
  let(:required_many_field) { { name: "departments", type: "string", index: true, "min-occurs" => 1, label: "desc" } }
  let(:date_field) { { name: "created_on", type: "date", label: "desc" } }
  let(:optional_field2) { { name: "updated_on", type: "date", label: "desc", index: false, "min-occurs" => 0, "max-occurs" => 1 } }

  describe "required indexed field" do
    it "submits the proper request" do
      request_body = <<-XML
<?xml version=\"1.0\"?>
<request>
  <service name=\"asset.doc.type.update\" session=\"secretsecret/2/31\">
    <args>
      <create>true</create>
      <description>test document schema</description>
      <type>tigerdata:project</type>
      <definition>
        <element name=\"code\" type=\"string\" index=\"true\" min-occurs=\"1\" max-occurs=\"1\" label=\"desc\"/>
      </definition>
    </args>
  </service>
</request>
XML

      stub_request(:post, mediaflux_url).with(body: request_body).to_return(status: 200, body: schema_fields_create_response, headers: {})

      request = described_class.new(
        schema_name: "tigerdata",
        document: "project",
        description: "test document schema",
        fields: [required_indexed_field],
        session_token: "secretsecret/2/31"
      )
      request.resolve

      expect(request.response_xml.to_s).to eq schema_fields_create_response
    end
  end

  describe "indexed not required field" do
    it "submits the proper request" do
      request_body = <<-XML
<?xml version=\"1.0\"?>
<request>
  <service name=\"asset.doc.type.update\" session=\"secretsecret/2/31\">
    <args>
      <create>true</create>
      <description>test document schema</description>
      <type>tigerdata:project</type>
      <definition>
        <element name=\"title\" type=\"string\" index=\"false\" min-occurs=\"1\" max-occurs=\"1\" label=\"desc\"/>
      </definition>
    </args>
  </service>
</request>
XML

      stub_request(:post, mediaflux_url).with(body: request_body).to_return(status: 200, body: schema_fields_create_response, headers: {})

      request = described_class.new(
        schema_name: "tigerdata",
        document: "project",
        description: "test document schema",
        fields: [required_not_indexed_field],
        session_token: "secretsecret/2/31"
      )
      request.resolve

      expect(request.response_xml.to_s).to eq schema_fields_create_response
    end
  end

  describe "optional field" do
    it "submits the proper request" do
      request_body = <<-XML
<?xml version=\"1.0\"?>
<request>
  <service name=\"asset.doc.type.update\" session=\"secretsecret/2/31\">
    <args>
      <create>true</create>
      <description>test document schema</description>
      <type>tigerdata:project</type>
      <definition>
        <element name=\"data_users_rw\" type=\"string\" index=\"false\" min-occurs=\"0\" label=\"desc\"/>
      </definition>
    </args>
  </service>
</request>
XML

      stub_request(:post, mediaflux_url).with(body: request_body).to_return(status: 200, body: schema_fields_create_response, headers: {})

      request = described_class.new(
        schema_name: "tigerdata",
        document: "project",
        description: "test document schema",
        fields: [optional_field],
        session_token: "secretsecret/2/31"
      )
      request.resolve

      expect(request.response_xml.to_s).to eq schema_fields_create_response
    end
  end

  describe "required many values field" do
    it "submits the proper request" do
      request_body = <<-XML
<?xml version=\"1.0\"?>
<request>
  <service name=\"asset.doc.type.update\" session=\"secretsecret/2/31\">
    <args>
      <create>true</create>
      <description>test document schema</description>
      <type>tigerdata:project</type>
      <definition>
        <element name=\"departments\" type=\"string\" index=\"true\" min-occurs=\"1\" label=\"desc\"/>
      </definition>
    </args>
  </service>
</request>
XML

      stub_request(:post, mediaflux_url).with(body: request_body).to_return(status: 200, body: schema_fields_create_response, headers: {})

      request = described_class.new(
        schema_name: "tigerdata",
        document: "project",
        description: "test document schema",
        fields: [required_many_field],
        session_token: "secretsecret/2/31"
      )
      request.resolve

      expect(request.response_xml.to_s).to eq schema_fields_create_response
    end
  end

  describe "a date field" do
    it "submits the proper request" do
      request_body = <<-XML
<?xml version=\"1.0\"?>
<request>
  <service name=\"asset.doc.type.update\" session=\"secretsecret/2/31\">
    <args>
      <create>true</create>
      <description>test document schema</description>
      <type>tigerdata:project</type>
      <definition>
        <element name=\"created_on\" type=\"date\" label=\"desc\"/>
      </definition>
    </args>
  </service>
</request>
XML

      stub_request(:post, mediaflux_url).with(body: request_body).to_return(status: 200, body: schema_fields_create_response, headers: {})

      request = described_class.new(
        schema_name: "tigerdata",
        document: "project",
        description: "test document schema",
        fields: [date_field],
        session_token: "secretsecret/2/31"
      )
      request.resolve

      expect(request.response_xml.to_s).to eq schema_fields_create_response
    end
  end

  describe "updated field" do
    it "submits the proper request" do
      request_body = <<-XML
<?xml version=\"1.0\"?>
<request>
  <service name=\"asset.doc.type.update\" session=\"secretsecret/2/31\">
    <args>
      <create>true</create>
      <description>test document schema</description>
      <type>tigerdata:project</type>
      <definition>
        <element name=\"updated_on\" type=\"date\" label=\"desc\" index=\"false\" min-occurs=\"0\" max-occurs=\"1\"/>
      </definition>
    </args>
  </service>
</request>
XML

      stub_request(:post, mediaflux_url).with(body: request_body).to_return(status: 200, body: schema_fields_create_response, headers: {})

      request = described_class.new(
        schema_name: "tigerdata",
        document: "project",
        description: "test document schema",
        fields: [optional_field2],
        session_token: "secretsecret/2/31"
      )
      request.resolve

      expect(request.response_xml.to_s).to eq schema_fields_create_response
    end
  end
end
