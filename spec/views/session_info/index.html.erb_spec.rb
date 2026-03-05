# frozen_string_literal: true
require "rails_helper"

RSpec.describe "session_info/index", type: :view do
  let(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  before(:each) do
    assign(:current_user, user)
    assign(:mediaflux_info, { version: "1001" })
    assign(:mediaflux_roles, ["role1", "role2"])
  end

  it "renders a mediaflux information" do
    render
    assert_select "p", "Connected to MediaFlux at #{Mediaflux::Connection.host} port 8888"
    assert_select "dd", user.uid
    assert_select "li", "role1"
    assert_select "li", "role2"
  end
end
