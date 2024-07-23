# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::SchemaCreateRequest, connect_to_mediaflux: true, type: :model do
  let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }
  let(:user) { FactoryBot.create(:user) }
  let(:approved_project) { FactoryBot.create(:approved_project) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<response><reply type=\"result\"><result></result></reply></response>" }

  let(:schema_create_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "schema_create_response.xml")
    File.new(filename).read
  end

  describe "#new" do

    it "creates a request with the indicated parameters" do
      schema_create_request = described_class.new(name: "tigerdata", description: "test schema", session_token: user.mediaflux_session)
      schema_create_request.resolve
      expect(schema_create_request.response_xml.to_s).to eq schema_create_response
    end
  end
end
