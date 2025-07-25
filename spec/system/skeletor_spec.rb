# frozen_string_literal: true

require "rails_helper"
require "open-uri"
# This is the automated test to the Skeletor epic https://github.com/pulibrary/tigerdata-app/issues/1478
RSpec.describe "The Skeletor Epic", connect_to_mediaflux: true, js: true, integration: true do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "TigerData Web Portal"
      expect(page).to have_content "Log in"
      expect(page).to have_link "Accessibility", href: "https://accessibility.princeton.edu/help"
    end
  end

  # Authenticated user logging in
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

  context "sysadmin" do
    let(:current_sysadmin) { FactoryBot.create(:sysadmin, uid: "sys123", mediaflux_session: SystemUser.mediaflux_session) }
    let(:datasponsor) { FactoryBot.create(:project_sponsor) } # we grabbed this from project.rb
    let(:datamanager) { FactoryBot.create(:data_manager) }
    before do
      datasponsor
    end
    it "allows the sysadmin to fill out the project" do
      # this is the feature flipper
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:new_project_request_wizard, true)
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      expect(Project.count).to eq 0
      sign_in current_sysadmin
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Basic Details"
      fill_in :project_title, with: "She was a Fairy"
      expect(page).to have_content "15/200 characters"
      fill_in :parent_folder, with: "Fairy"
      fill_in :project_folder, with: "Pixie Dust"
      fill_in :description, with: "An awesome project to show the wizard is magic"
      expect(page).to have_content "46/1000 characters"
      expect(page).not_to have_content("(77777) RDSS-Research Data and Scholarship Services")
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select "(77777) RDSS-Research Data and Scholarship Services\u00A0", from: "department_find"
      # This is triggering the html5 element like it would normally if the page has focus
      page.find(:datalist_input, "department_find").execute_script("document.getElementById('department_find').dispatchEvent(new Event('input'))")
      expect(page).to have_content("(77777) RDSS-Research Data and Scholarship Services")
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
      click_on "Roles and People"
      fill_in :request_data_sponsor, with: datasponsor.uid
      fill_in :request_data_manager, with: datamanager.uid
      click_on "Review and Submit"
      click_on "Next"
      click_on "Approve request"
      expect(Project.last.metadata_json["project_id"]).to eq "10.34770/tbd"
      visit "/projects/#{Project.last.id}.xml"
      expect(page.body).to include("<resource")
    end
  end

  context "superuser" do
    let(:current_superuser) { FactoryBot.create(:superuser, uid: "superuser1", mediaflux_session: SystemUser.mediaflux_session) }
    let(:datasponsor) { FactoryBot.create(:project_sponsor) } # we grabbed this from project.rb
    let(:datamanager) { FactoryBot.create(:data_manager) }
    before do
      datasponsor
    end
    it "allows the superuser to fill out the project" do
      # this is the feature flipper
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:new_project_request_wizard, true)
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      expect(Project.count).to eq 0
      sign_in current_superuser
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Basic Details"
      fill_in :project_title, with: "She was a Fairy"
      expect(page).to have_content "15/200 characters"
      fill_in :parent_folder, with: "Fairy"
      fill_in :project_folder, with: "Pixie Dust"
      fill_in :description, with: "An awesome project to show the wizard is magic"
      expect(page).to have_content "46/1000 characters"
      expect(page).not_to have_content("(77777) RDSS-Research Data and Scholarship Services")
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select "(77777) RDSS-Research Data and Scholarship Services\u00A0", from: "department_find"
      # This is triggering the html5 element like it would normally if the page has focus
      page.find(:datalist_input, "department_find").execute_script("document.getElementById('department_find').dispatchEvent(new Event('input'))")
      expect(page).to have_content("(77777) RDSS-Research Data and Scholarship Services")
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
      click_on "Roles and People"
      fill_in :request_data_sponsor, with: datasponsor.uid
      fill_in :request_data_manager, with: datamanager.uid
      click_on "Review and Submit"
      click_on "Next"
      click_on "Approve request"
      expect(Project.last.metadata_json["project_id"]).to eq "10.34770/tbd"
      visit "/projects/#{Project.last.id}.xml"
      expect(page.body).to include("<resource")
    end
  end
end

# once a sysadmin or superuser click on approve request then it should take us to the details page and display the project ID. This is the fake DOI (10.34770/tbd)
