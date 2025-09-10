# frozen_string_literal: true
require "rails_helper"

RSpec.describe "mediaflux_info/index", type: :view do
  before(:each) do
    assign(:mf_version, { version: "1001" })
    assign(:mediaflux_roles, ["role1", "role2"])
  end

  it "renders a mediaflux information" do
    render
    assert_select "p", "Connected to MediaFlux 1001 at #{Mediaflux::Connection.host}"
    assert_select "li", "role1"
    assert_select "li", "role2"
  end
end
