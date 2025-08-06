# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::SessionExpired, connect_to_mediaflux: true, type: :model do
  let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:project1) { FactoryBot.create(:approved_project) }

  it "can be instantiated" do
    sessionexpired = Mediaflux::SessionExpired.new(session_token: user.mediaflux_session, project: project1, token: nil)
    expect(sessionexpired).to be_instance_of Mediaflux::SessionExpired
  end
end
