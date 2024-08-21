# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::AssetExistRequest, type: :model, connect_to_mediaflux: true do
  let(:user) { FactoryBot.create(:user) }
  let(:namespace_root) { Rails.configuration.mediaflux["api_root_collection_namespace"] }

  context "when we give a user to the class" do
    it "sends the custom HTTP headers to Mediaflux" do
      subject = described_class.new(session_token: nil, session_user: user, path: namespace_root)
      http_request = subject.send("http_request")
      expect(http_request["mediaflux.sso.user"]).to eq user.uid
    end
  end

  context "when we give a session token to the class" do
    it "does NOT send the custom HTTP headers to Mediaflux" do
      subject = described_class.new(session_token: user.mediaflux_session, session_user: nil, path: namespace_root)
      http_request = subject.send("http_request")
      expect(http_request["mediaflux.sso.user"]).to be nil
    end
  end
end
