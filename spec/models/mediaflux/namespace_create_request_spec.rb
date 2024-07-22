# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceCreateRequest, connect_to_mediaflux: true ,type: :model do
  let(:mediaflux_url) { "#{Rails.configuration.mediaflux["api_host"].to_s}/#{Rails.configuration.mediaflux["api_port"].to_s}" }
  let(:user) { FactoryBot.create(:user)}

  describe "#resolve" do
    it "disconnects the session" do
      namespace_request = described_class.new(session_token: user.mediaflux_session, namespace: "td-test-001")
      namespace_request.resolve
      expect(namespace_request.resolved?).to eq true
    end
  end
end
