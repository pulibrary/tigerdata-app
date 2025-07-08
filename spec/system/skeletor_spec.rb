# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WelcomeController", connect_to_mediaflux: true, js: true, integration: true do 
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "TigerData Web Portal"
      expect(page).to have_content "Log in"
      expect(page).to have_link "Accessibility", href: "https://accessibility.princeton.edu/help"
    end
end

    #Authenticated user logging in
    context "authenticated user" do
        let(:current_user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
        it "redirects to the user's dashboard and shows the logout button" do
        sign_in current_user
        visit "/"
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        click_link current_user.uid.to_s
        expect(page).to have_content "Log out"
        end
    end
end