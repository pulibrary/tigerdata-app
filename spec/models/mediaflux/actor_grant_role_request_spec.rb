# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ActorGrantRoleRequest, connect_to_mediaflux: true, type: :model, integration: true do
  let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  it "can be instantiated" do
    new_instance = Mediaflux::ActorGrantRoleRequest.new(session_token: user.mediaflux_session, type: "user", name: "princeton:#{user.uid}", role: "system-administrator")
    response = new_instance.resolve
    expect(response.code).to eq "200"
    # This is not actually granting sysadmin. How do we turn the user into a sysadmin?
  end
end
