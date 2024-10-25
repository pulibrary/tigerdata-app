# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::VersionRequest, connect_to_mediaflux: true, type: :model do
  subject(:request) { described_class.new(session_token: session_token) }
  let(:session_token) { user.mediaflux_session }
  let(:user) { FactoryBot.create(:user) }
  let(:docker_response) { "4.16.071" }
  let(:ansible_response) { "4.16.047" }

  describe "#resolve" do
    it "authenticates and stores the session token" do
      request.resolve

      expect(request.version[:vendor]).to eq("Arcitecta Pty. Ltd.")
      expect(request.version[:version]).to eq(docker_response).or eq(ansible_response)
    end
  end
end
