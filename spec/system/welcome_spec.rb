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
      expect(page).to have_button "Login"
      expect(page).to have_link "Learn More", href: "https://tigerdata.princeton.edu"
      expect(find("#login-button").ancestor("form")[:action]).to include "users/auth/cas"
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
    let(:researcher_user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
    let(:sysadmin_user) { FactoryBot.create(:sysadmin, mediaflux_session: SystemUser.mediaflux_session) }

    it "redirects to the user's dashboard and shows the logout button" do
      sign_in researcher_user
      visit "/"

      expect(page).to have_content("Welcome, #{researcher_user.given_name}!")
      click_link researcher_user.uid.to_s
      expect(page).to have_content "Log out"
    end

    it "shows the new request multi button to sysadmin users" do
      FactoryBot.create(:request, project_title: "A new draft request", requested_by: sysadmin_user.uid)
      other_request = FactoryBot.create(:request, project_title: "Other draft request", requested_by: sysadmin_user.uid)
      FactoryBot.create(:request, project_title: "A new submitted request", requested_by: sysadmin_user.uid, state: Request::SUBMITTED)
      sign_in sysadmin_user
      visit "/"

      expect(page).to have_content "New Project Request"
      find(".request-options").click

      expect(page).to have_content "Submitted Requests"
      click_on "Submitted Requests"
      expect(page).to have_content "A new submitted request"
      expect(page).to have_link("Open")

      expect(page).to have_content "Saved Draft Requests"
      click_on "Saved Draft Requests"
      expect(page).to have_content "A new draft request"
      expect(page).to have_content "Other draft request"
      within("#draft-request-#{other_request.id}") do
        click_on "Delete"
      end
      expect(page).to have_content("You're about to delete the draft request \"#{other_request.project_title}\".")
      click_on "Cancel"
      expect(page).not_to have_content("You're about to delete the draft request \"#{other_request.project_title}\".")
      within("#draft-request-#{other_request.id}") do
        click_on "Delete"
      end
      click_on "Permanently Delete"
      expect(page).to have_content("Your file has been permanently deleted.")
      click_on "Back to draft requests"
      click_on "Open"
      expect(page).to have_content("New Project Request")
      expect(page).to have_content("Review")
    end
  end
end
