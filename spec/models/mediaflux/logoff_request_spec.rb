# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::LogoutRequest, connect_to_mediaflux: true, type: :model do
  subject(:request) { described_class.new(session_token: session_token) }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:session_token) { user.mediaflux_session }
  let(:mediaflux_url) { Mediaflux::Request.uri.to_s }

  describe "#resolve" do
    it "disconnects the session" do
      request.resolve
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<service name=\"system.logoff\"")
      end).to have_been_made
    end
  end
end
