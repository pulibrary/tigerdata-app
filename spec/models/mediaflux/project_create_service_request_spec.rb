# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ProjectCreateServiceRequest, connect_to_mediaflux: true, type: :model do
  let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  let(:project1) { FactoryBot.create(:approved_project) }
  let(:mpcsr) { Mediaflux::ProjectCreateServiceRequest.new(session_token: user.mediaflux_session, project: project1, token: nil) }

  it "can be instantiated" do
    expect(mpcsr).to be_instance_of Mediaflux::ProjectCreateServiceRequest
  end

  it "can be resolved" do
    expect(mpcsr.resolved?).to eq false
    mpcsr.resolve
    expect(mpcsr.resolved?).to eq true
  end
end
