# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::VersionRequest, connect_to_mediaflux: true, type: :model do
  subject(:request) { described_class.new(session_token: session_token) }
  let(:session_token) { user.mediaflux_session }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:expected_mflux_version) { Mediaflux::EXPECTED_VERSION }

  describe "#resolve" do
    it "authenticates and stores the session token" do
      request.resolve

      expect(request.version[:vendor]).to eq("Arcitecta Pty. Ltd.")
      expect(request.version[:version].match?(expected_mflux_version)).to eq true
    end
  end
end
