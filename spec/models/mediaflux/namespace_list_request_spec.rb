# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceListRequest,connect_to_mediaflux: true, type: :model do
  let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }
  let(:user) { FactoryBot.create(:user) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n" }

  describe "#metadata" do

    it "parses a metadata response" do
      namespace_request = described_class.new(session_token: user.mediaflux_session, parent_namespace: "/td-test-001")
      namespaces = namespace_request.namespaces
      expect(namespaces.count).to eq(1)

      # namespace id changes every time so we only test for the name of the namespace
      expect(namespaces.first[:name]).to eq("test")
      expect(namespace_request.response_body).to include(mediaflux_response)
    end
  end
end
