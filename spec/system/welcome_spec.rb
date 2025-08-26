# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WelcomeController", connect_to_mediaflux: true, js: true do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "TigerData Web Portal"
      expect(page).to have_content "Log in"
      expect(page).to have_link "Accessibility", href: "https://accessibility.princeton.edu/help"
    end

    it "shows the 'Learn More' button, which goes to the TigerData service page" do
      visit "/"
      expect(page).to have_button "Learn More"
      click_button "Learn More"
      assert_current_path("https://tigerdata.princeton.edu")
    end

    it "forwards to login page" do
      project = FactoryBot.create(:project)
      visit project_path(project)
      expect(page).to have_content "You need to sign in or sign up before continuing."
    end

    it "hides the 'Administration' tab" do
      visit "/"
      expect(page).to have_content "TigerData Web Portal"
      expect(page).not_to have_content "Administration"
    end

    context "flash message" do
      let(:non_admin_user) { FactoryBot.create(:user) }
      it "shows the flash message" do
        sign_in non_admin_user
        visit "/projects"
        expect(page).to have_content("Access Denied")
      end
    end
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
    let(:admin_user) { FactoryBot.create(:sysadmin, mediaflux_session: SystemUser.mediaflux_session) }

    it "redirects to the user's dashboard and shows the logout button" do
      sign_in current_user
      visit "/"

      expect(page).to have_content("Welcome, #{current_user.given_name}!")
      click_link current_user.uid.to_s
      expect(page).to have_content "Log out"
    end

    it "does not show the new request multi button to just any user" do
      sign_in current_user
      visit "/"

      expect(page).to have_content("Welcome, #{current_user.given_name}!")
      expect(page).not_to have_content "New Project Request"
    end

    it "shows the new request multi button to sysadmin users" do
      sign_in admin_user
      visit "/"

      expect(page).to have_content "New Project Request"
      find(".request-options").click
      expect(page).to have_content "Saved Draft Requests"
      click_on "Saved Draft Requests"
      expect(page).to have_content "I should have the list of draft"
    end
  end
end
