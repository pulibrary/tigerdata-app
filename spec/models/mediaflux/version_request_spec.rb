# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::VersionRequest, connect_to_mediaflux: true, type: :model do
  subject(:request) { described_class.new(session_token: session_token) }
  let(:session_token) { user.mediaflux_session }
  let(:user) { FactoryBot.create(:user) }

  describe "#resolve" do
    it "authenticates and stores the session token" do
      request.resolve

      expect(request.version[:vendor]).to eq("Arcitecta Pty. Ltd.")
      expect(request.version[:version]).to eq("4.16.047")
    end
  end
end
