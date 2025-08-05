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

  # When Mediaflux creates a project, it returns an xml snippet with the Mediaflux id.
  # If the id is an integer, it is valid. If the id is anything else, then forcing it
  # to be an integer will return zero.
  it "parses an id number" do
    expect(mpcsr.mediaflux_id.to_i).not_to eq 0
  end
end
