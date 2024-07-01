# frozen_string_literal: true

require "rails_helper"

describe "mediaflux_info", type: :system, js: true, connect_to_mediaflux: true do
  let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
  it "shows the mediaflux version" do
    sign_in current_user
    visit "/mediaflux_info"
    expect(page).to have_content("Connected to MediaFlux")
    expect(page).to have_content("Mediaflux Port:\n8888\n")
  end
end
