# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceListRequest, connect_to_mediaflux: true, type: :model do
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n" }

  describe "#metadata" do
    it "parses a metadata response" do
      namespace_request = described_class.new(session_token: user.mediaflux_session, parent_namespace: "/princeton")
      namespaces = namespace_request.namespaces
      tigerdata_ns = namespaces.select { |ns| ns[:name] == "tigerdataNS" }

      expect(tigerdata_ns.count).to eq(1)
      expect(namespace_request.response_body).to include(mediaflux_response)
    end
  end
end
