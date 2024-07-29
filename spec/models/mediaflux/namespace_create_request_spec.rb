# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceCreateRequest, connect_to_mediaflux: true, type: :model do
  # let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }
  let(:user) { FactoryBot.create(:user) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<response><reply type=\"result\"><result></result></reply></response>" }

  describe "#resolve" do
    before do
      # delete the namespace if it exists
      destroy_request = Mediaflux::NamespaceDestroyRequest.new(session_token: user.mediaflux_session, namespace: "td-test-001")
      destroy_request.destroy
    end
    after do
      create_request = Mediaflux::NamespaceCreateRequest.new(
      session_token: user.mediaflux_session,
      namespace: Rails.configuration.mediaflux[:api_root_to_clean]
    )
      create_request.resolve
    end

    it "disconnects the session" do
      namespace_request = described_class.new(session_token: user.mediaflux_session, namespace: "td-test-001")
      namespace_request.resolve
      expect(namespace_request.error?).to eq false
      expect(namespace_request.response_body).to eq mediaflux_response
    end
  end
end
