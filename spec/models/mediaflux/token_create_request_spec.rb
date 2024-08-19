# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::TokenCreateRequest, connect_to_mediaflux: true, type: :model do
  subject(:request) { described_class.new(session_token: session_token, domain: Mediaflux::LogonRequest.mediaflux_domain, user: Mediaflux::LogonRequest.mediaflux_user) }
  let(:user) { FactoryBot.create(:user) }
  let(:session_token) { user.mediaflux_session }
  let(:mediaflux_url) { Mediaflux::Request.uri.to_s }

  describe "#identity" do
    it "creates an identity token for the user" do
      expect(request.identity.nil?).to eq false

      assert_requested(:post, mediaflux_url,
                       body: /<grant-user-roles>true<\/grant-user-roles>.*<domain>system<\/domain>.*<user>manager<\/user>/m)
    end
  end
end
