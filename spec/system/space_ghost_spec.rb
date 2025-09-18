# frozen_string_literal: true

require "rails_helper"
require "open-uri"

RSpec.describe "The Space Ghost Epic", connect_to_mediaflux: true, js: true, integration: true do
  context "user" do
    let(:user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
    it "displays the new project wizard on the dashboard" do
      sign_in user
      visit "/"
      expect(page).to have_content("Welcome, #{user.given_name}!")
      byebug
    end
  end
end
