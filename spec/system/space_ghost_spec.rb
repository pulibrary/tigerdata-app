# frozen_string_literal: true

require "rails_helper"
require "open-uri"

RSpec.describe "The Space Ghost Epic", type: :system, connect_to_mediaflux: false, js: true do
  context "user" do
    let(:user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }

    it "contains the fields of the drupal form when creating a project" do
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      another_user = FactoryBot.create(:user)
      datasponsor = FactoryBot.create(:project_sponsor)
      datamanager = FactoryBot.create(:data_manager)
      expect(Project.count).to eq 0
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

      # This part of the test is filling out the data manager and sponsor
      expect(page).to have_content("Assign roles for your project")
      select_user(datasponsor, "request_data_sponsor", "request[data_sponsor]")
      select_user(datamanager, "request_data_manager", "request[data_manager]")

      # This part of the test is filling out the data users
      click_on "Add User(s)"
      fill_in :user_find, with: another_user.uid
      sleep(1.2)
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      another_user_str = another_user.display_name_safe
      select another_user_str + "\u00A0", from: "user_find"
      click_on "Add Users"

      # This part of the code is going through the rest of the fields of the wizard form to review and submit the project request
      click_on "Next"
      expect(page).to have_content("Enter the storage and access needs for your project.")
      click_on "Next"
      expect(page).to have_content("Take a moment to review your details and make any necessary edits before finalizing.")
      click_on "Submit"
      expect(page).to have_content("Your new project request is submitted")
    end
  end
end
