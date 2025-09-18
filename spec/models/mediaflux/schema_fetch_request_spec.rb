# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::SchemaFetchRequest, connect_to_mediaflux: true, type: :model, integration: true do
  let(:namespace) { "tigerdata" }
  let(:type) { "tigerdata:project" }
  let(:session_token) { Mediaflux::LogonRequest.new.session_token }
  let(:field_without_label) do
    xml = '<element name="ProjectPurpose" type="string" min-occurs="0" max-occurs="1"><description>The high-level category for the purpose of the project</description></element>'
    doc = Nokogiri(xml)
    doc.children.first
  end

  describe "#field_from_element" do
    it "handles fields without a label gracefully" do
      request = described_class.new(session_token: session_token, namespace: namespace, type: type)
      field = request.send( :field_from_element, field_without_label)
      expect(field[:label]).to eq field[:name]
    end
  end
end
