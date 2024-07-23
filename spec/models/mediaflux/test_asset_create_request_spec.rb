# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::TestAssetCreateRequest, connecnt_to_mediaflux: true, type: :model do
  let(:user) { FactoryBot.create(:user) }
  # let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }

  describe "#resolve" do
    it "disconnects the session" do
      namespace_request = described_class.new(session_token: user.mediaflux_session, parent_id: 123, count: 20, pattern: "abc")
      namespace_request.resolve
      expect(namespace_request.resolved?).to eq true
    end
  end
end
