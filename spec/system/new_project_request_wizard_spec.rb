# frozen_string_literal: true

require "rails_helper"

describe "New Project Request page", type: :system, connect_to_mediaflux: false, clean_projects: true, js: true do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "TigerData Web Portal"
      expect(page).to have_content "Log in"
      expect(page).to have_link "Accessibility", href: "https://accessibility.princeton.edu/help"
    end
  end

  context "authenticated user" do
    context "a sysadmin user" do
      let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "sys123", mediaflux_session: SystemUser.mediaflux_session) }
      let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "kl37") } # must be a valid netid
      let(:manager_user) { FactoryBot.create(:data_manager, uid: "rl3667") } # must be a valid netid
      before do
        sponsor_user
      end
      it "allows the sysadmin to fill out the project" do
        Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
        expect(Project.count).to eq 0
        sign_in sysadmin_user
        visit "/"
        click_on "New Project Request"
        expect(page).to have_content "Basic Details"
        fill_in :project_title, with: "She was a Fairy"
        expect(page).to have_content "15/200 characters"
        fill_in :parent_folder, with: "Fairy"
        fill_in :project_folder, with: "Pixie_Dust_#{random_project_directory}"
        fill_in :description, with: "An awesome project to show the wizard is magic"
        select "Teaching", from: :project_purpose
        expect(page).to have_content "46/1000 characters"
        expect(page).not_to have_content("RDSS-Research Data and Scholarship Services")
        select_and_verify_department(department: "RDSS-Research Data and Scholarship Services", department_code: "77777", department_list: [])
        expect(page).to have_content("RDSS-Research Data and Scholarship Services")
        expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
        click_on "Roles and People"
        select_user(sponsor_user, "data_sponsor", "request[data_sponsor]")
        select_user(manager_user, "data_manager", "request[data_manager]")
        click_on "Review and Submit"
        expect(page).to have_content "Take a moment to review"
        click_on "Submit"
        expect(page).to have_content("Your new project request is submitted")
        visit "/requests/#{Request.last.id}"
        click_on "Approve request"
        expect(Project.last.metadata_json["project_id"]).to eq "10.34770/tbd"
        visit "/projects/#{Project.last.id}.xml"
        expect(page.body).to include("<resource")
      end
    end

    context "developer" do
      let(:developer_user) { FactoryBot.create(:developer, uid: "developer1", mediaflux_session: SystemUser.mediaflux_session) }
      let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "kl37") } # must be a valid netid
      let(:manager_user) { FactoryBot.create(:data_manager, uid: "rl3667") } # must be a valid netid
      before do
        sponsor_user
      end
      it "allows the developer to fill out the project" do
        Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
        expect(Project.count).to eq 0
        sign_in developer_user
        visit "/"
        click_on "New Project Request"
        expect(page).to have_content "Basic Details"
        fill_in :project_title, with: "She was a Fairy"
        expect(page).to have_content "15/200 characters"
        fill_in :parent_folder, with: "Fairy"
        fill_in :project_folder, with: "Pixie_Dust_#{random_project_directory}"
        fill_in :description, with: "An awesome project to show the wizard is magic"
        select "Teaching", from: :project_purpose
        expect(page).to have_content "46/1000 characters"
        expect(page).not_to have_content("(77777) RDSS-Research Data and Scholarship Services")
        select_and_verify_department(department: "RDSS-Research Data and Scholarship Services", department_code: "77777", department_list: [])
        expect(page).to have_content("RDSS-Research Data and Scholarship Services")
        expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
        click_on "Roles and People"
        select_user(sponsor_user, "data_sponsor", "request[data_sponsor]")
        select_user(manager_user, "data_manager", "request[data_manager]")
        click_on "Review and Submit"
        expect(page).to have_content "Take a moment to review"
        click_on "Submit"
        expect(page).to have_content("Your new project request is submitted")
        visit "/requests/#{Request.last.id}"
        click_on "Approve request"
        expect(Project.last.metadata_json["project_id"]).to eq "10.34770/tbd"
        visit "/projects/#{Project.last.id}.xml"
        expect(page.body).to include("<resource")
      end
    end

    context "tester-trainer user" do
      let!(:trainer_user) { FactoryBot.create(:trainer, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
      let(:user_a) { FactoryBot.create(:user, uid: "cac9") }
      let(:user_b) { FactoryBot.create(:user, uid: "jrg5") }
      let(:request1) { FactoryBot.create :request_project, data_manager: "tigerdatatester", data_sponsor: "tigerdatatester" }
      let(:project1) { request1.approve(trainer_user) }
      let(:request2) { FactoryBot.create :request_project, data_manager: "tigerdatatester", data_sponsor: "tigerdatatester", user_roles: [{ "uid" => user_b.uid, "read_only" => false }] }
      let(:project2) { request2.approve(trainer_user) }
      it "does not allow a user to see someone elses project" do
        sign_in user_a
        visit "/projects/#{project1.id}"
        expect(page).to have_content("Access Denied")
        visit "/projects/#{project1.id}.xml"
        expect(page).to have_content("Access Denied")
      end

      it "allows a user to see a project they are affiliated with" do
        sign_in user_b
        visit "/projects/#{project2.id}"
        expect(page).to have_content(project2.title)
        visit "/projects/#{project2.id}.xml"
        expect(page.body).to include(project2.title)
      end
    end

    context "research user" do
      let(:researcher_user) { FactoryBot.create(:user, uid: "pul123", display_name: "Sally O'Smith") }
      it "Supports all the Shippable Increment fields on the basic information page" do
        # TODO: Add tests for all the shippable increment fields as they are added to the wizard
        Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))

        other_user = FactoryBot.create(:user)
        another_user = FactoryBot.create(:user)
        manager_user = FactoryBot.create(:user)

        sign_in researcher_user
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
        select "Research", from: "project_purpose"
        expect(page).not_to have_content("RDSS-Research Data and Scholarship Services")
        select_and_verify_department(department: "RDSS-Research Data and Scholarship Services", department_code: "77777", department_list: [])

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
        expect(page).to have_content("RDSS-Research Data and Scholarship Services")
        expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
        click_on "Next"
        # TODO: when the wizard is fully functional the correct next step(s) are below
        # expect(page).to have_content "Categories (Optional)"
        # click_on "Next"
        # expect(page).to have_content "Dates (Optional)"
        # click_on "Next"
        expect(page).to have_content("Assign roles for your project")

        select_user(researcher_user, "data_sponsor", "request[data_sponsor]")
        select_user(manager_user, "data_manager", "request[data_manager]")

        # Fill in a partial match to force the textbox to fetch a list of options to select from
        click_on "Add User(s)"

        select_data_user(another_user, [{ label: another_user.display_name_safe, id: another_user.uid }])

        # we can remove the user in the modal
        page.find(".lux-button.remove-item").click
        expect(page).not_to have_content(another_user.given_name)
        expect(page).to have_field("all_selected", type: :hidden, with: "[]")

        # we can remove all the users from the table and have it stick between page loads
        select_data_user(another_user, [{ label: another_user.display_name_safe, id: another_user.uid }])
        click_on "Add Users"
        expect(page).to have_content("1 new user(s) were successfully added.")
        expect(page).not_to have_content("0 duplicate user(s) were ignored.")
        expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{another_user.uid}\",\"name\":\"#{another_user.display_name_safe}\"}")
        click_on "Next"
        expect(page).to have_content("Enter the storage and access needs for your project")
        click_on "Back"
        expect(page).to have_content("Assign roles for your project")
        within(".user-input-display") do
          page.execute_script("document.getElementsByClassName('remove-item')[0].click()")
        end
        click_on "Next"
        expect(page).to have_content("Enter the storage and access needs for your project")
        click_on "Back"
        expect(page).to have_content("Assign roles for your project")
        expect(page).not_to have_content(another_user.given_name)

        click_on "Add User(s)"
        select_data_user(another_user, [{ label: another_user.display_name_safe, id: another_user.uid }])
        select_data_user(other_user, [{ label: another_user.display_name_safe, id: another_user.uid },
                                      { label: other_user.display_name_safe, id: other_user.uid }])
        select_data_user(researcher_user, [{ label: another_user.display_name_safe, id: another_user.uid },
                                           { label: other_user.display_name_safe, id: other_user.uid },
                                           { label: researcher_user.display_name_safe, id: researcher_user.uid }])
        select_data_user(manager_user, [{ label: another_user.display_name_safe, id: another_user.uid },
                                        { label: other_user.display_name_safe, id: other_user.uid },
                                        { label: researcher_user.display_name_safe, id: researcher_user.uid },
                                        { label: manager_user.display_name_safe, id: manager_user.uid }])

        click_on "Add Users"

        expect(page).to have_field("request[read_only_#{another_user.uid}]", type: :radio)
        expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{another_user.uid}\",\"name\":\"#{another_user.display_name_safe}\"}")
        expect(page).to have_content(another_user.display_name_safe)
        expect(page).not_to have_content("#{another_user.display_name_safe} (#{another_user.uid})")

        expect(page).to have_field("request[read_only_#{other_user.uid}]", type: :radio)
        expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{other_user.uid}\",\"name\":\"#{other_user.display_name_safe}\"}")
        expect(page).to have_content(other_user.display_name_safe)

        expect(page).to have_content("2 duplicate user(s) were ignored. 2 new user(s) were successfully added.")

        click_on "Add User(s)"
        select_data_user(other_user, [{ label: other_user.display_name_safe, id: other_user.uid }])

        click_on "Add Users"

        expect(page).to have_content("1 duplicate user(s) were ignored. 0 new user(s) were successfully added.")
        expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{other_user.uid}\",\"name\":\"#{other_user.display_name_safe}\"}").once

        choose("request[read_only_#{another_user.uid}]", option: "false")

        click_on "Back"
        # TODO: when the wizard is fully functional the Dates should be back
        # expect(page).to have_content "Dates (Optional)"
        sleep(0.1)
        expect(page).to have_content "Tell us a little about your project!"
        click_on "Next"
        expect(page).to have_content("Assign roles for your project")
        expect(page).to have_content "Roles and People"
        expect(page).to have_content "Data Manager"
        expect(page.find("#data_sponsor_input input").value).to eq(researcher_user.display_name_safe)
        expect(page).to have_field("request[data_sponsor]", type: :hidden, with: researcher_user.uid)
        expect(page.find("#data_manager_input input").value).to eq(manager_user.display_name_safe)
        expect(page).to have_field("request[data_manager]", type: :hidden, with: manager_user.uid)
        expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{another_user.uid}\",\"name\":\"#{another_user.display_name_safe}\",\"read_only\":false}")
        expect(page).to have_field("request[user_roles][]", type: :hidden, with: "{\"uid\":\"#{other_user.uid}\",\"name\":\"#{other_user.display_name_safe}\",\"read_only\":true}")
        expect(page).not_to have_content("#{researcher_user.display_name_safe} (#{researcher_user.uid})")
      end

      # Consolidate the tests for each shippable increment of the wizard below

      it "walks through the wizard if the feature is enabled" do
        sign_in researcher_user
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
        request = Request.create(requested_by: researcher_user.uid)
        sign_in researcher_user
        visit "/new-project/review-submit/#{request.id}"
        expect(page).to have_content "Take a moment to review"
        click_on("Submit")
        within(".project-title") do
          expect(page).to have_content("This field is required.")
        end

        expect(page).to have_content("Please resolve errors before submitting your request")
        fill_in :project_title, with: "A basic Project"
        expect(page).to have_content "15/200 characters"

        click_on("Submit")
        within(".parent-folder") do
          expect(page).to have_content("This field is required.")
        end

        fill_in :parent_folder, with: "abc_lab"
        click_on("Submit")
        within(".project-folder") do
          expect(page).to have_content("This field is required.")
        end

        fill_in :project_folder, with: "skeletor"
        select "Teaching", from: :project_purpose
        fill_in :description, with: "An awesome project to show the wizard is magic"
        expect(page).to have_content "46/1000 characters"
        expect(page).not_to have_content("RDSS-Research Data and Scholarship Services")
        select_and_verify_department(department: "RDSS-Research Data and Scholarship Services", department_code: "77777", department_list: [])
        select_and_verify_department(department: "HPC-High Performance Computing", department_code: "66666", department_list: [{ code: "77777", name: "RDSS-Research Data and Scholarship Services" }])

        select_user(researcher_user, "data_sponsor", "request[data_sponsor]")
        select_user(researcher_user, "data_manager", "request[data_manager]")

        click_on("Submit")
        expect(page).to have_content("Your new project request is submitted")
      end

      it "saves work in progress if user jumps to another step in the wizard" do
        Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))

        sign_in researcher_user
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

        sign_in researcher_user
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
        department_to_test = "RDSS-Research Data and Scholarship Services"
        select_and_verify_department(department: department_to_test, department_code: "77777", department_list: [])

        # Remove the department
        within(".departments") do
          page.execute_script("document.getElementsByClassName('remove-item')[0].click()")
        end
        expect(page).not_to have_content(department_to_test)
      end

      it "does not allow save and exit for a request with missing titles" do
        sign_in researcher_user
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
        sign_in researcher_user
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

      it "does not allow requests to be submitted with duplicate departments." do
        Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
        sign_in researcher_user
        visit "new-project/project-info"

        select_and_verify_department(department: "RDSS-Research Data and Scholarship Services", department_code: "77777", department_list: [])
        # the option is no longer available
        within(".departments") do
          page.find(".lux-field input").fill_in with: "77777"
          within(".lux-autocomplete-input") do
            expect(page).not_to have_content "RDSS-Research Data and Scholarship Services"
          end
        end

        expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
        expect(page).to have_content("RDSS-Research Data and Scholarship Services").exactly(1).times

        click_on "Review and Submit"
        expect(page).to have_content("Take a moment to review your details and make any necessary edits before finalizing.")
        expect(page).to have_content("RDSS-Research Data and Scholarship Services").exactly(1).times

        fill_in :project_title, with: "No Duplicate Departments Project"
        fill_in :parent_folder, with: "abc_lab"
        fill_in :project_folder, with: "skeletor"
        fill_in :description, with: "An awesome project to show the wizard is magic"
        select "Research", from: "project_purpose"
        select_user(researcher_user, "data_sponsor", "request[data_sponsor]")
        select_user(researcher_user, "data_manager", "request[data_manager]")

        click_on "Submit"
        expect(page).to have_content("Your new project request is submitted")

        visit "requests/#{Request.last.id}"
        expect(page).to have_content("No Duplicate Departments Project")
        expect(page).to have_content("RDSS-Research Data and Scholarship Services").exactly(1).times
      end

      it "allows for save and exit" do
        sign_in researcher_user
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

      it "automatically saves and redirects the user to the dashboard when a user clicks the dashboard breadcrumb" do
        sign_in researcher_user
        visit "/"
        click_on "New Project Request"
        expect(page).to have_content "Tell us a little about your project!"
        fill_in :project_title, with: "Dashboard Redirect Test"

        # Clicking on the breadcrumb saves the user changes
        click_on "Dashboard"
        expect(page).to have_content "Welcome, #{researcher_user.given_name}!"
        request = Request.last
        expect(request.project_title).to eq("Dashboard Redirect Test")
        expect(page).to have_content("Draft request saved automatically")
      end

      it "automatically saves and redirects the user to the dashboard when a user clicks the tigerdata logo" do
        sign_in researcher_user
        visit "/"
        click_on "New Project Request"
        expect(page).to have_content "Tell us a little about your project!"
        fill_in :project_title, with: "Dashboard Redirect Test"

        # Clicking on the TigerData logo saves the user changes
        find("#logo.header-image").click
        expect(page).to have_content "Welcome, #{researcher_user.given_name}!"
        request = Request.last
        expect(request.project_title).to eq("Dashboard Redirect Test")
        expect(page).to have_content("Draft request saved automatically")
      end

      it "allows a user to click a step in the side panel and a flash message is not displayed" do
        sign_in researcher_user
        visit "/"
        click_on "New Project Request"
        expect do
          expect(page).to have_content "Tell us a little about your project!"
          fill_in :project_title, with: "Dashboard Redirect Test"

          # Clicking on the side panel step does not display the flash message
          click_on "Roles and People"
          expect(page).not_to have_content "Draft request saved automatically"
          request = Request.last
          expect(request.project_title).to eq("Dashboard Redirect Test")
        end.to change { Request.count }.by(1)
      end
    end
  end
end
