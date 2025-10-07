# frozen_string_literal: true
#
# We send custom properties to plausible.io to help with analytics
# Documentation here: https://plausible.io/docs/custom-event-goals

require "rails_helper"

describe "Plausible custom properties", type: :system, connect_to_mediaflux: false, js: true do
  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123", sysadmin: true) }
    it "notifies plausible when a request is begun" do
      sign_in current_user
      visit "/"
      expect(page.find("#new-project-request-wizard-button")[:class]).to eq "plausible-event-name=New+Project+Request"
    end

    it "notifies plausible for each step in the wizard" do
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      sign_in current_user

      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Tell us a little about your project!"
      expect(page.find("#next-button")[:class]).to match(/plausible-event-name=new_project_wizard_project_information/)
      click_on "Next"
      expect(page).to have_content "Assign roles for your project"
      expect(page.find("#next-button")[:class]).to match(/plausible-event-name=new_project_wizard_roles_and_people/)
      click_on "Next"
      expect(page).to have_content "Enter the storage and access needs"
      expect(page.find("#next-button")[:class]).to match(/plausible-event-name=new_project_wizard_storage_and_access/)
      click_on "Next"
      expect(page).to have_content "Take a moment to review"
      expect(page.find("#next-button")[:class]).to match(/plausible-event-name=new_project_wizard_review_and_submit/)
    end
  end
end
