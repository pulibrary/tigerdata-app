# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ActorRevokeRoleRequest, connect_to_mediaflux: true, type: :model do
  let(:user) { FactoryBot.create(:user, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  describe "#resolve" do
    it "Removes a user from the pu-lib:developer group", :integration do
      revoke_role_request = described_class.new(session_token: user.mediaflux_session, type: "user", user: user, role: "pu-lib:developer")
      revoke_role_request.resolve

      expect(revoke_role_request.error?).to be false
      expect(revoke_role_request.roles).to eq [""]
    end
  end
end
