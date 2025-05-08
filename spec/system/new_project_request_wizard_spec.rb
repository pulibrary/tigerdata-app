# frozen_string_literal: true

require "rails_helper"

describe "New Project Request page", type: :system, connect_to_mediaflux: false, js: true do
  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:new_project_request_wizard, true)
  end

  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "Log in"
    end
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
    it "walks through the wizard" do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:new_project_request_wizard, true)
      sign_in current_user
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Project Information: Basic"
      click_on "Next"
      expect(page).to have_content "Project Information: Categories"
      click_on "Next"
      expect(page).to have_content "Project Information: Dates"
      click_on "Next"
      expect(page).to have_content "Roles and People"
      click_on "Next"
      expect(page).to have_content "Project Type"
      click_on "Next"
      expect(page).to have_content "Storage and Access"
      click_on "Next"
      expect(page).to have_content "Additional Information: Grants and Funding"
      click_on "Next"
      expect(page).to have_content "Additional Information: Project Permissions"
      click_on "Next"
      expect(page).to have_content "Additional Information: Related Resources"
      click_on "Next"
      expect(page).to have_content "Review and Submit"
      click_on "Back"
      expect(page).to have_content "Additional Information: Related Resources"
      click_on "Back"
      expect(page).to have_content "Additional Information: Project Permissions"
      click_on "Back"
      expect(page).to have_content "Additional Information: Grants and Funding"
      click_on "Back"
      expect(page).to have_content "Storage and Access"
      click_on "Back"
      expect(page).to have_content "Project Type"
      click_on "Back"
      expect(page).to have_content "Roles and People"
      click_on "Back"
      expect(page).to have_content "Project Information: Dates"
      click_on "Back"
      expect(page).to have_content "Project Information: Categories"
      click_on "Back"
      expect(page).to have_content "Project Information: Basic"
    end
  end
end
