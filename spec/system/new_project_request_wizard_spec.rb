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
    it "walks through the wizard if the feature is enabled" do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:new_project_request_wizard, true)
      sign_in current_user
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Basic Details"
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
      expect(page).to have_content "Basic Details"
    end

    it "cannot walk through the wizard if the feature is disabled" do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:new_project_request_wizard, false)
      request = Request.create
      sign_in current_user
      visit "/"
      expect(page).not_to have_content("New Project Request")
      visit "/new-project/project-info/#{request.id}"
      expect(page).not_to have_content "Basic Details"
      visit "/new-project/project-info-categories/#{request.id}"
      expect(page).not_to have_content "Project Information: Categories"
      visit "/new-project/project-info-dates/#{request.id}"
      expect(page).not_to have_content "Project Information: Dates"
      visit "/new-project/roles-people/#{request.id}"
      expect(page).not_to have_content "Roles and People"
      visit "/new-project/project-type/#{request.id}"
      expect(page).not_to have_content "Project Type"
      visit "/new-project/storage-access/#{request.id}"
      expect(page).not_to have_content "Storage and Access"
      visit "/new-project/additional-info-grants-funding/#{request.id}"
      expect(page).not_to have_content "Additional Information: Grants and Funding"
      visit "/new-project/additional-info-project-permissions/#{request.id}"
      expect(page).not_to have_content "Additional Information: Project Permissions"
      visit "/new-project/additional-info-related-resources/#{request.id}"
      expect(page).not_to have_content "Additional Information: Related Resources"
      visit "/new-project/review-submit/#{request.id}"
      expect(page).not_to have_content "Review and Submit"
    end
  end
end
