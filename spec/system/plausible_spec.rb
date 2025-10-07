# frozen_string_literal: true
#
# We send custom properties to plausible.io to help with analytics
# Documentation here: https://plausible.io/docs/custom-event-goals

require "rails_helper"

describe "Plausible custom properties", type: :system, connect_to_mediaflux: false, js: true do
  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123", sysadmin: true) }
    it "notifies plausible when a project request is begun" do
      sign_in current_user
      visit "/"
      expect(page.find("#new-project-request-wizard-button")[:class]).to eq "plausible-event-name=New+Project+Request"
    end

    it "notifies plausible when a request is submitted" do
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      sign_in current_user

      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Tell us a little about your project!"
      byebug
      click_on "Next"
      expect(page).to have_content "Assign roles for your project"
      click_on "Next"
      expect(page).to have_content "Enter the storage and access needs"
      click_on "Next"
      expect(page).to have_content "Take a moment to review"
      click_on "Back"
      expect(page).to have_content "Enter the storage and access needs"
      click_on "Back"
      expect(page).to have_content "Assign roles for your project"
      click_on "Back"
      expect(page).to have_content "Tell us a little about your project!"
    end
  end
end
