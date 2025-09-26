# frozen_string_literal: true

require "rails_helper"
require "open-uri"

RSpec.describe "The Space Ghost Epic", type: :system, connect_to_mediaflux: false, js: true do
  context "user" do
    let(:user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
    let(:datasponsor) { FactoryBot.create(:project_sponsor, uid: "kl37") } # must be a valid netid
    let(:datamanager) { FactoryBot.create(:data_manager, uid: "rl3667") } # must be a valid netid
    before do
      datasponsor
    end
    it "displays the new project wizard on the dashboard" do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:allow_all_users_wizard_access, true)
      sign_in user
      visit "/"
      expect(page).to have_content("Welcome, #{user.given_name}!")
      test_strategy.switch!(:allow_all_users_wizard_access, false)
    end
    it "contains the fields of the drupal form when creating a project" do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:allow_all_users_wizard_access, true)
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      expect(Project.count).to eq 0
      another_user = FactoryBot.create(:user)
      sign_in user
      visit "/"
      expect(page).to have_content("Welcome, #{user.given_name}!")
      click_on "New Project Request"
      expect(page).to have_content "Basic Details"
      fill_in :project_title, with: "She was a Fairy"
      expect(page).to have_content "15/200 characters"
      fill_in :parent_folder, with: "Fairy"
      fill_in :project_folder, with: "Pixie Dust #{random_project_directory}"
      fill_in :description, with: "An awesome project to show the wizard is magic"
      select "Teaching", from: :project_purpose
      expect(page).to have_content "46/1000 characters"
      expect(page).not_to have_content("(77777) RDSS-Research Data and Scholarship Services")
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select "(77777) RDSS-Research Data and Scholarship Services\u00A0", from: "department_find"
      # This is triggering the html5 element like it would normally if the page has focus
      page.find(:datalist_input, "department_find").execute_script("document.getElementById('department_find').dispatchEvent(new Event('input'))")
      expect(page).to have_content("(77777) RDSS-Research Data and Scholarship Services")
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
      click_on "Next"
      expect(page).to have_content("Assign roles for your project")
      fill_in :request_data_sponsor, with: datasponsor.uid
      fill_in :request_data_manager, with: datamanager.uid
      click_on "Add User(s)"
      fill_in :user_find, with: another_user.uid
      sleep(1.2)
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      another_user_str = "(#{another_user.uid}) #{another_user.display_name}"
      select another_user_str + "\u00A0", from: "user_find"
      click_on "Add Users"

      # next step is to click on "add user" then figure out how to load in the user for the druple
      test_strategy.switch!(:allow_all_users_wizard_access, false)
    end
  end
end
