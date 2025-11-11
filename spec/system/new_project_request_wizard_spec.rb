# frozen_string_literal: true

require "rails_helper"

describe "New Project Request page", type: :system, connect_to_mediaflux: false, js: true do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "Log in"
    end
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123", sysadmin: true) }
    it "walks through the wizard if the feature is enabled" do
      sign_in current_user
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Tell us a little about your project!"
      click_on "Next"
      # TODO: when the wizard is fully functional the correct next step(s) are below
      # expect(page).to have_content "Categories (Optional)"
      # click_on "Next"
      # expect(page).to have_content "Dates (Optional)"
      # click_on "Next"
      expect(page).to have_content "Assign roles for your project"
      click_on "Next"
      # TODO: when the wizard is fully functional the correct next step(s) are below
      # expect(page).to have_content "Project Type"
      # click_on "Next"
      expect(page).to have_content "Enter the storage and access needs"
      click_on "Next"
      # TODO: when the wizard is fully functional the correct next step(s) are below
      # expect(page).to have_content "Funding Sources"
      # click_on "Next"
      # expect(page).to have_content "Project Permissions"
      # click_on "Next"
      # expect(page).to have_content "Related Resources"
      # click_on "Next"
      expect(page).to have_content "Take a moment to review"
      expect(page).to have_button "Submit"
      click_on "Back"
      # TODO: when the wizard is fully functional the correct next step(s) are below
      # expect(page).to have_content "Related Resources"
      # click_on "Back"
      # expect(page).to have_content "Project Permissions"
      # click_on "Back"
      # expect(page).to have_content "Funding Sources"
      # click_on "Back"
      expect(page).to have_content "Enter the storage and access needs"
      click_on "Back"
      # TODO: when the wizard is fully functional the correct next step(s) are below
      # expect(page).to have_content "Project Type"
      # click_on "Back"
      expect(page).to have_content "Assign roles for your project"
      click_on "Back"
      # TODO: when the wizard is fully functional the correct next step(s) are below
      # expect(page).to have_content "Dates (Optional)"
      # click_on "Back"
      # expect(page).to have_content "Categories (Optional)"
      # click_on "Back"
      expect(page).to have_content "Tell us a little about your project!"
    end

    it "can not submit if the request is not valid" do
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      request = Request.create
      sign_in current_user
      visit "/"
      click_on "New Project Request"
      visit "/new-project/review-submit/#{request.id}"
      expect(page).to have_content "Take a moment to review"
      click_on("Submit")
      within(".project-title") do
        expect(page).to have_content("cannot be empty")
      end
      expect(page).to have_content("Please resolve errors before submitting your request")
      fill_in :project_title, with: "A basic Project"
      expect(page).to have_content "15/200 characters"
      fill_in :parent_folder, with: "abc_lab"
      fill_in :project_folder, with: "skeletor"
      select "Teaching", from: :project_purpose
      fill_in :description, with: "An awesome project to show the wizard is magic"
      expect(page).to have_content "46/1000 characters"
      expect(page).not_to have_content("(77777) RDSS-Research Data and Scholarship Services")
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select "(77777) RDSS-Research Data and Scholarship Services\u00A0", from: "department_find"
      # This is triggering the html5 element like it would normally if the page has focus
      page.find(:datalist_input, "department_find").execute_script("document.getElementById('department_find').dispatchEvent(new Event('input'))")
      expect(page).to have_content("(77777) RDSS-Research Data and Scholarship Services")
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
      current_user_str = current_user.display_name_safe

      # Fill in a partial match to force the textbox to fetch a list of options to select from
      fill_in :request_data_sponsor, with: current_user.uid
      sleep(1.2)
      select current_user_str + "\u00A0", from: "request_data_sponsor"

      # Fill in a partial match to force the textbox to fetch a list of options to select from
      fill_in :request_data_manager, with: current_user.uid
      sleep(1.2)
      select current_user_str + "\u00A0", from: "request_data_manager"

      click_on("Submit")
      expect(page).to have_content("Your new project request is submitted")
    end

    context "non sysadmin user" do
      let(:current_user) { FactoryBot.create(:user, uid: "pul123") }

      it "allows users to walk through the wizard" do
        sign_in current_user
        visit "/"
        click_on "New Project Request"
        expect(page).to have_content "Tell us a little about your project!"
        expect(page).not_to have_button "Back"
        click_on "Next"
        expect(page).to have_content "Assign roles for your project"
        expect(page).to have_button "Back"
        click_on "Next"
        expect(page).to have_content "Enter the storage and access needs"
        # Check that TB is listed as default
        find('label[for="radiocustom"]').click
        expect(page).to have_select("storage_unit", selected: "TB")
        expect(page).to have_button "Back"
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

    it "Supports all the Skeletor fields on the basic information page" do
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))

      other_user = FactoryBot.create(:user)
      another_user = FactoryBot.create(:user)

      sign_in current_user
      visit "/"
      click_on "New Project Request"

      # Check that the current step (1) is marked as such and the next one (2) is be marked as incomplete
      expect(find(".step-number-current .step-text").text).to eq "1"
      expect(all(".step-number-incomplete .step-text")[0].text).to eq "2"

      expect(page).to have_content "Tell us a little about your project!"
      fill_in :project_title, with: "A basic Project"
      expect(page).to have_content "15/200 characters"
      fill_in :parent_folder, with: "abc_lab"
      fill_in :project_folder, with: "skeletor"
      fill_in :description, with: "An awesome project to show the wizard is magic"
      expect(page).to have_content "46/1000 characters"
      expect(page).not_to have_content("(77777) RDSS-Research Data and Scholarship Services")
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select "(77777) RDSS-Research Data and Scholarship Services\u00A0", from: "department_find"
      select "Research", from: "project_purpose"
      # This is triggering the html5 element like it would normally if the page has focus
      page.find(:datalist_input, "department_find").execute_script("document.getElementById('department_find').dispatchEvent(new Event('input'))")
      expect(page).to have_content("(77777) RDSS-Research Data and Scholarship Services")
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")

      # force a save and page reload to make sure all data is being saved to the model
      click_on "Next"

      # TODO: when the wizard is fully functional the Categories should be next
      # expect(page).to have_content "Categories (Optional)"
      # click_on "Next"

      expect(page).to have_content "Assign roles for your project"

      # Check that the current step (2) is marked as such and the previous one (1) has been marked as completed
      expect(find(".step-number-current .step-text").text).to eq "2"
      expect(all(".step-number-completed .step-text")[0].text).to eq "1"

      click_on("Back")
      expect(page).to have_content "Tell us a little about your project!"
      expect(page).to have_field("project_title", with: "A basic Project")
      expect(page).to have_field("parent_folder", with: "abc_lab")
      expect(page).to have_field("project_folder", with: "skeletor")
      expect(page).to have_field("description", with: "An awesome project to show the wizard is magic")
      expect(page).to have_content("(77777) RDSS-Research Data and Scholarship Services")
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
      click_on "Next"
      # TODO: when the wizard is fully functional the correct next step(s) are below
      # expect(page).to have_content "Categories (Optional)"
      # click_on "Next"
      # expect(page).to have_content "Dates (Optional)"
      # click_on "Next"
      expect(page).to have_content("Assign roles for your project")

      select_user(current_user, "request_data_sponsor", "request[data_sponsor]")
      select_user(current_user, "request_data_manager", "request[data_manager]")

      # Fill in a partial match to force the textbox to fetch a list of options to select from
      click_on "Add User(s)"
      another_user_str = another_user.display_name_safe
      fill_in :user_find, with: another_user.uid
      sleep(1.2)
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select another_user_str + "\u00A0", from: "user_find"

      # The another user selected is visible on the page
      expect(page).to have_content(another_user_str)
      # the javascript created the hidden form element
      expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{another_user.uid}\",\"name\":\"#{another_user.display_name_safe}\"}")
      page.find(".remove-user-role").click
      expect(page).not_to have_content(another_user_str)

      current_user_str = current_user.display_name_safe

      fill_in :user_find, with: current_user.uid
      sleep(1.2)
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select current_user_str + "\u00A0", from: "user_find"

      # The user selected is visible on the page
      expect(page).to have_content(current_user_str)
      expect(page).not_to have_content("(#{current_user.uid}) #{current_user_str}")
      # the javascript created the hidden form element
      expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{current_user.uid}\",\"name\":\"#{current_user.display_name_safe}\"}")
      # the javascript cleared the find to get ready for the next search
      expect(page).to have_field("user_find", with: "")

      other_user_str = other_user.display_name_safe
      fill_in :user_find, with: other_user.uid
      sleep(1.2)
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select other_user_str + "\u00A0", from: "user_find"

      # The other user selected is visible on the page
      expect(page).to have_content(other_user_str)
      # the javascript created the hidden form element
      expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{other_user.uid}\",\"name\":\"#{other_user.display_name_safe}\"}")
      # the javascript cleared the find to get ready for the next search
      expect(page).to have_field("user_find", with: "")

      click_on "Add Users"

      expect(page).to have_field("request[read_only_#{current_user.uid}]", type: :radio)
      expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{current_user.uid}\",\"name\":\"#{current_user.display_name_safe}\"}")
      expect(page).to have_content(current_user_str)
      expect(page).not_to have_content("#{current_user_str} (#{current_user.uid})")

      expect(page).to have_field("request[read_only_#{other_user.uid}]", type: :radio)
      expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{other_user.uid}\",\"name\":\"#{other_user.display_name_safe}\"}")
      expect(page).to have_content(other_user_str)

      choose("request[read_only_#{current_user.uid}]", option: "false")

      click_on "Back"
      # TODO: when the wizard is fully functional the Dates should be back
      # expect(page).to have_content "Dates (Optional)"
      sleep(0.1)
      expect(page).to have_content "Tell us a little about your project!"
      click_on "Next"
      expect(page).to have_content("Assign roles for your project")
      expect(page).to have_content "Roles and People"
      expect(page).to have_content "Data Manager"
      expect(page).to have_field("request_data_sponsor", with: current_user.display_name_safe)
      expect(page).to have_field("request[data_sponsor]", type: :hidden, with: current_user.uid)
      expect(page).to have_field("request_data_manager", with: current_user.display_name_safe)
      expect(page).to have_field("request[data_manager]", type: :hidden, with: current_user.uid)
      expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{current_user.uid}\",\"name\":\"#{current_user.display_name_safe}\",\"read_only\":false}")
      expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{other_user.uid}\",\"name\":\"#{other_user.display_name_safe}\",\"read_only\":true}")
      expect(page).not_to have_content("#{current_user.display_name_safe} (#{current_user.uid})")
    end

    it "saves work in progress if user jumps to another step in the wizard" do
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))

      sign_in current_user
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Tell us a little about your project!"
      random_title = "Project #{rand(100_000)} title"
      fill_in :project_title, with: random_title

      # Click on the last step in the Wizard
      # and make sure the data from the previous step was saved
      click_on "Review and Submit"
      expect(page).to have_field("project_title", with: random_title)
    end

    it "deletes departments when clicking on the X next to them" do
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))

      sign_in current_user
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Tell us a little about your project!"
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

    it "allows for Exit without Saving" do
      sign_in current_user
      visit "/"
      expect do
        click_on "New Project Request"
        expect(page).to have_content "Basic Details"
        fill_in :project_title, with: "A basic Project"
        click_on "Save and exit"
        expect(page).to have_content "will be saved as draft"
        click_on "Exit without Saving"
        expect(page).to have_content("Welcome")
      end.not_to change { Request.count }
    end

    it "does not allow save and exit for a request with missing titles" do
      sign_in current_user
      visit "new-project/project-info"
      expect do
        expect(page).to have_content "Basic Details"
        fill_in :project_title, with: ""
        click_on "Save and exit"
        expect(page).to have_content "will be saved as draft"
        expect(page).to have_field("project_title_exit", with: "")
        expect(page).to have_button("Confirm", disabled: true)
        fill_in :project_title_exit, with: "A basic Project updated"
        expect(page).to have_button("Confirm", disabled: false)
        click_on "Confirm"
        expect(page).to have_content("Your new project request has been saved")
        expect(page).to have_content("A basic Project updated")
      end.to change { Request.count }.by(1)
    end

    it "does not allow save and exit for a request with an empty titles with spaces" do
      sign_in current_user
      visit "new-project/project-info"
      expect do
        expect(page).to have_content "Basic Details"
        fill_in :project_title, with: "   "
        click_on "Save and exit"
        expect(page).to have_content "will be saved as draft"
        expect(page).to have_field("project_title_exit", with: "   ")
        expect(page).to have_button("Confirm", disabled: true)
        fill_in :project_title_exit, with: "A basic Project updated"
        expect(page).to have_button("Confirm", disabled: false)
        click_on "Confirm"
        expect(page).to have_content("Your new project request has been saved")
        expect(page).to have_content("A basic Project updated")
      end.to change { Request.count }.by(1)
    end

    it "allows for save and exit" do
      sign_in current_user
      visit "/"
      expect do
        click_on "New Project Request"
        expect(page).to have_content "Basic Details"
        fill_in :project_title, with: "A basic Project"
        click_on "Save and exit"
        expect(page).to have_content "will be saved as draft"
        expect(page).to have_field("project_title_exit", with: "A basic Project")
        fill_in :project_title_exit, with: "A basic Project updated"
        click_on "Confirm"
        expect(page).to have_content("Your new project request has been saved")
        expect(page).to have_content("A basic Project updated")
      end.to change { Request.count }.by(1)
    end
  end
end
