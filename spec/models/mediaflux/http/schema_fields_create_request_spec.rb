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
  let(:optional_field) do
    {
      name: "data_users", type: "string", index: false, "min-occurs" => 0, label: "label", description: "element description",
      instructions: "do this, not that",
      attributes: [{ name: "read_only", type: "boolean", index: false, "min-occurs" => 0, description: "desc" }]
    }
  end
  let(:required_many_field) { { name: "departments", type: "string", index: true, "min-occurs" => 1, label: "desc" } }
  let(:date_field) { { name: "created_on", type: "date", label: "desc", index: false, "min-occurs" => 1, "max-occurs" => 1 } }
  let(:optional_field2) { { name: "updated_on", type: "date", label: "desc", index: false, "min-occurs" => 0, "max-occurs" => 1 } }
  let(:nested_field) do
    requested_by = { name: "RequestedBy", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Requested By",
                     description: "The person who made the request",
                     instructions: "The person who made the request, given as a locally unique user." }
    requested_date = { name: "RequestDateTime", type: "date", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Request Date-Time", description: "The date and time the request was made",
                       instructions: "The date and time the request was made, following ISO 8601 standards for timestamps." }
    note_by = { name: "NoteBy", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Note By", description: "The person making the note." }
    note_date = { name: "NoteDateTime", type: "date", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Note Date-Time", description: "The date and time the note was made" }
    note_type = { name: "EventType", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Event Type", description: "A general category label for the event note" }
    message = { name: "Message", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Message", description: "The plain-language message contents of the event note." }
    event_note = { name: "EventlNote", type: "document", index: false, "min-occurs" => 0, label: "Event Note(s)", description: "A supplementary record for a provenance event",
                   instructions: "A supplementary record of noteworthy details for a given provenance event (e.g., quota decisions, storage tier assignments, revisions to submitted " \
                                 "metadata, explanations of extenuating circumstances, etc.)",
                   sub_elements: [note_by, note_date, note_type, message] }
    { name: "Submission", type: "document", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Submission", description: "A record of a project’s initial submission",
      instructions: "A record of a project’s initial submission, including the request to create a new project and the approval or denial by system administrators.",
      sub_elements: [requested_by, requested_date, event_note] }
  end

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
        <element name="data_users" type="string" index="false" min-occurs="0" label="label">
          <attribute name=\"read_only\" type=\"boolean\" index=\"false\" min-occurs=\"0\">
            <description>desc</description>
          </attribute>
          <description>element description</description>
          <instructions>do this, not that</instructions>
        </element>
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
        <element name=\"created_on\" type=\"date\" label=\"desc\" index=\"false\" min-occurs=\"1\" max-occurs=\"1\"/>
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

  describe "nested fields" do
    it "submits the proper request" do
      request_body = <<-XML
<?xml version="1.0"?>
<request>
  <service name="asset.doc.type.update" session="secretsecret/2/31">
    <args>
      <create>true</create>
      <description>test document schema</description>
      <type>tigerdata:project</type>
      <definition>
        <element name="Submission" type="document" index="false" min-occurs="1" max-occurs="1" label="Submission">
          <description>A record of a project&#x2019;s initial submission</description>
          <instructions>A record of a project&#x2019;s initial submission, including the request to create a new project and the approval or denial by system administrators.</instructions>
          <element name="RequestedBy" type="string" index="false" min-occurs="1" max-occurs="1" label="Requested By">
            <description>The person who made the request</description>
            <instructions>The person who made the request, given as a locally unique user.</instructions>
          </element>
          <element name="RequestDateTime" type="date" index="false" min-occurs="1" max-occurs="1" label="Request Date-Time">
            <description>The date and time the request was made</description>
            <instructions>The date and time the request was made, following ISO 8601 standards for timestamps.</instructions>
          </element>
          <element name="EventlNote" type="document" index="false" min-occurs="0" label="Event Note(s)">
            <description>A supplementary record for a provenance event</description>
            <instructions>A supplementary record of noteworthy details for a given provenance event (e.g., quota decisions, storage tier assignments, revisions to submitted metadata, explanations of extenuating circumstances, etc.)</instructions>
            <element name="NoteBy" type="string" index="false" min-occurs="1" max-occurs="1" label="Note By">
              <description>The person making the note.</description>
            </element>
            <element name="NoteDateTime" type="date" index="false" min-occurs="1" max-occurs="1" label="Note Date-Time">
              <description>The date and time the note was made</description>
            </element>
            <element name="EventType" type="string" index="false" min-occurs="1" max-occurs="1" label="Event Type">
              <description>A general category label for the event note</description>
            </element>
            <element name="Message" type="string" index="false" min-occurs="1" max-occurs="1" label="Message">
              <description>The plain-language message contents of the event note.</description>
            </element>
          </element>
        </element>
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
        fields: [nested_field],
        session_token: "secretsecret/2/31"
      )
      request.resolve

      expect(request.response_xml.to_s).to eq schema_fields_create_response
    end
  end
end
