# frozen_string_literal: true
require "rails_helper"

RSpec.describe "mediaflux_info/index", type: :view do
  before(:each) do
    assign(:mf_version, { version: "1001" })
  end

  it "renders a mediaflux information" do
    render
    assert_select "p", "Connected to MediaFlux 1001 at 0.0.0.0"
  end
end
