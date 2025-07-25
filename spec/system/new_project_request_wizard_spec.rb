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
    let(:current_user) { FactoryBot.create(:user, uid: "pul123", sysadmin: true) }
    it "walks through the wizard if the feature is enabled" do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:new_project_request_wizard, true)
      sign_in current_user
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Basic Details"
      click_on "Next"
      expect(page).to have_content "Categories (Optional)"
      click_on "Next"
      expect(page).to have_content "Dates (Optional)"
      click_on "Next"
      expect(page).to have_content "Roles and People"
      click_on "Next"
      expect(page).to have_content "Project Type"
      click_on "Next"
      expect(page).to have_content "Storage and Access"
      click_on "Next"
      expect(page).to have_content "Funding Sources"
      click_on "Next"
      expect(page).to have_content "Project Permissions"
      click_on "Next"
      expect(page).to have_content "Related Resources"
      click_on "Next"
      expect(page).to have_content "Review and Submit"
      click_on "Back"
      expect(page).to have_content "Related Resources"
      click_on "Back"
      expect(page).to have_content "Project Permissions"
      click_on "Back"
      expect(page).to have_content "Funding Sources"
      click_on "Back"
      expect(page).to have_content "Storage and Access"
      click_on "Back"
      expect(page).to have_content "Project Type"
      click_on "Back"
      expect(page).to have_content "Roles and People"
      click_on "Back"
      expect(page).to have_content "Dates (Optional)"
      click_on "Back"
      expect(page).to have_content "Categories (Optional)"
      click_on "Back"
      expect(page).to have_content "Basic Details"
    end

    it "can not submit if the request is not valid" do
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:new_project_request_wizard, true)
      request = Request.create
      sign_in current_user
      visit "/"
      click_on "New Project Request"
      visit "/new-project/review-submit/#{request.id}"
      expect(page).to have_content "Review and Submit"
      click_on("Next")
      within(".project-title") do
        expect(page).to have_content("cannot be empty")
      end
      expect(page.body).to include("Please resolve errors before submitting your request")
      fill_in :project_title, with: "A basic Project"
      expect(page).to have_content "15/200 characters"
      fill_in :parent_folder, with: "abc_lab"
      fill_in :project_folder, with: "skeletor"
      fill_in :description, with: "An awesome project to show the wizard is magic"
      expect(page).to have_content "46/1000 characters"
      expect(page).not_to have_content("(77777) RDSS-Research Data and Scholarship Services")
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select "(77777) RDSS-Research Data and Scholarship Services\u00A0", from: "department_find"
      # This is triggering the html5 element like it would normally if the page has focus
      page.find(:datalist_input, "department_find").execute_script("document.getElementById('department_find').dispatchEvent(new Event('input'))")
      expect(page).to have_content("(77777) RDSS-Research Data and Scholarship Services")
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
      current_user_str = "(#{current_user.uid}) #{current_user.display_name}"
      select current_user_str, from: "request_data_sponsor"
      select current_user_str, from: "request_data_manager"
      click_on("Next")
      expect(page).to have_content("Request state: submitted")
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
      expect(page).not_to have_content "Categories (Optional)"
      visit "/new-project/project-info-dates/#{request.id}"
      expect(page).not_to have_content "Dates (Optional)"
      visit "/new-project/roles-people/#{request.id}"
      expect(page).not_to have_content "Roles and People"
      visit "/new-project/project-type/#{request.id}"
      expect(page).not_to have_content "Project Type"
      visit "/new-project/storage-access/#{request.id}"
      expect(page).not_to have_content "Storage and Access"
      visit "/new-project/additional-info-grants-funding/#{request.id}"
      expect(page).not_to have_content "Funding Sources"
      visit "/new-project/additional-info-project-permissions/#{request.id}"
      expect(page).not_to have_content "Project Permissions"
      visit "/new-project/additional-info-related-resources/#{request.id}"
      expect(page).not_to have_content "Related Resources"
      visit "/new-project/review-submit/#{request.id}"
      expect(page).not_to have_content "Review and Submit"
    end

    it "Supports all the Skeletor fields on the basic information page" do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:new_project_request_wizard, true)
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))

      sign_in current_user
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Basic Details"
      fill_in :project_title, with: "A basic Project"
      expect(page).to have_content "15/200 characters"
      fill_in :parent_folder, with: "abc_lab"
      fill_in :project_folder, with: "skeletor"
      fill_in :description, with: "An awesome project to show the wizard is magic"
      expect(page).to have_content "46/1000 characters"
      expect(page).not_to have_content("(77777) RDSS-Research Data and Scholarship Services")
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select "(77777) RDSS-Research Data and Scholarship Services\u00A0", from: "department_find"
      # This is triggering the html5 element like it would normally if the page has focus
      page.find(:datalist_input, "department_find").execute_script("document.getElementById('department_find').dispatchEvent(new Event('input'))")
      expect(page).to have_content("(77777) RDSS-Research Data and Scholarship Services")
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")

      # force a save and page reload to make sure all data is being saved to the model
      click_on "Next"
      expect(page).to have_content "Categories (Optional)"
      click_on("Back")
      expect(page).to have_content "Basic Details"
      expect(page).to have_field("project_title", with: "A basic Project")
      expect(page).to have_field("parent_folder", with: "abc_lab")
      expect(page).to have_field("project_folder", with: "skeletor")
      expect(page).to have_field("description", with: "An awesome project to show the wizard is magic")
      expect(page).to have_content("(77777) RDSS-Research Data and Scholarship Services")
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
      click_on "Next"
      expect(page).to have_content "Categories (Optional)"
      click_on "Next"
      expect(page).to have_content "Dates (Optional)"
      click_on "Next"
      expect(page).to have_content "Roles and People"
      current_user_str = "(#{current_user.uid}) #{current_user.display_name}"
      select current_user_str, from: "request_data_sponsor"
      select current_user_str, from: "request_data_manager"
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select current_user_str + "\u00A0", from: "user_find"
      # The user selected is visible on the page
      expect(page).to have_content(current_user_str)
      # the javascript created the hidden form element
      expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{current_user.uid}\",\"name\":\"#{current_user.display_name}\"}")
      # the javascript cleared the find to get ready for the next search
      expect(page).to have_field("user_find", with: "")
      click_on "Back"
      expect(page).to have_content "Dates (Optional)"
      click_on "Next"
      expect(page).to have_content "Roles and People"
      expect(page).to have_content "Data Manager"
      expect(page).to have_field("request_data_sponsor", with: current_user.uid)
      expect(page).to have_field("request_data_manager", with: current_user.uid)
      expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{current_user.uid}\",\"name\":\"#{current_user.display_name}\"}")
    end

    it "saves work in progress if user jumps to another step in the wizard" do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:new_project_request_wizard, true)
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))

      sign_in current_user
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Basic Details"
      random_title = "Project #{rand(100_000)} title"
      fill_in :project_title, with: random_title

      # Click on the last step in the Wizard
      # and make sure the data from the previous step was saved
      click_on "Review and Submit"
      expect(page).to have_field("project_title", with: random_title)
    end

    it "deletes departments when clicking on the X next to them" do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:new_project_request_wizard, true)
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))

      sign_in current_user
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Basic Details"
      fill_in :project_title, with: "A basic Project"
      expect(page).to have_content "15/200 characters"
      fill_in :parent_folder, with: "abc_lab"
      fill_in :project_folder, with: "skeletor"
      fill_in :description, with: "An awesome project to show the wizard is magic"
      expect(page).to have_content "46/1000 characters"

      # Select a department
      department_to_test = "(77777) RDSS-Research Data and Scholarship Services"
      expect(page).not_to have_content(department_to_test)
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select "#{department_to_test}\u00A0", from: "department_find"
      # This is triggering the html5 element like it would normally if the page has focus
      page.find(:datalist_input, "department_find").execute_script("document.getElementById('department_find').dispatchEvent(new Event('input'))")
      expect(page).to have_content(department_to_test)
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")

      # Remove the department
      page.execute_script("document.getElementsByClassName('remove-department')[0].click()")
      expect(page).not_to have_content(department_to_test)
    end
  end
end
