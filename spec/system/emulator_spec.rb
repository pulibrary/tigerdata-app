# frozen_string_literal: true

require "rails_helper"

describe "Website banner", type: :system, connect_to_mediaflux: true, js: true do
  let(:trainer_user) { FactoryBot.create(:trainer, uid: "pul123") }
  it "has the banner on the homepage" do
    sign_in trainer_user
    visit "/"
    expect(page).to have_css "#emulator"
  end
end
