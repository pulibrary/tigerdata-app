# frozen_string_literal: true

require "rails_helper"

describe "mediaflux_info", type: :system, js: true, connect_to_mediaflux: true do
  let(:current_user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
  let(:mflux_port) { Rails.configuration.mediaflux["api_port"] }

  it "shows the mediaflux version" do
    sign_in current_user
    visit "/mediaflux_info"
    expect(page).to have_content("Connected to MediaFlux")
    expect(page).to have_content("Mediaflux Port:\n#{mflux_port}\n")
    expect(page).to have_content("Mediaflux Roles:")
    expect(page).to have_content("system-administrator")  # Role of our user while running the tests
  end
end
