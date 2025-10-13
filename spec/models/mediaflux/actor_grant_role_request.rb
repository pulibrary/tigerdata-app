# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ActorGrantRoleRequest, connect_to_mediaflux: true, type: :model do
  let(:user) { FactoryBot.create(:user, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  describe "#resolve" do
    it "Adds a user to the pu-lib:developer group", :integration do
      grant_role_request = described_class.new(session_token: user.mediaflux_session, type: "user", user: user, role: "pu-lib:developer")
      grant_role_request.resolve

      expect(grant_role_request.error?).to be false
      expect(grant_role_request.roles).to eq [""]
    end
  end
end
