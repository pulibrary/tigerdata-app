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
        expect(page).to have_css("#project_title")
        fill_in_and_out("project_title", with: "She was a Fairy")
        expect(page).to have_field("project_title", with: "She was a Fairy")
        fill_in :parent_folder, with: "Fairy"
        fill_in :project_folder, with: "Pixie_Dust_#{random_project_directory}"
        fill_in_and_out("description", with: "An awesome project to show the wizard is magic")
        expect(page).to have_field("description", with: "An awesome project to show the wizard is magic")
        select "Teaching", from: :project_purpose
        # Assert not selected (Lux may keep option labels in the DOM once mounted)
        expect(page).not_to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
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
        visit new_project_request_path(NewProjectRequest.last.id)
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
        expect(page).to have_css("#project_title")
        fill_in_and_out("project_title", with: "She was a Fairy")
        expect(page).to have_field("project_title", with: "She was a Fairy")
        fill_in :parent_folder, with: "Fairy"
        fill_in :project_folder, with: "Pixie_Dust_#{random_project_directory}"
        fill_in_and_out("description", with: "An awesome project to show the wizard is magic")
        expect(page).to have_field("description", with: "An awesome project to show the wizard is magic")
        select "Teaching", from: :project_purpose
        expect(page).not_to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
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
        visit new_project_request_path(NewProjectRequest.last.id)
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
        expect(page).to have_css("#project_title")
        fill_in_and_out("project_title", with: "A basic Project")
        expect(page).to have_field("project_title", with: "A basic Project")
        fill_in :parent_folder, with: "abc_lab"
        fill_in :project_folder, with: "skeletor"
        fill_in_and_out("description", with: "An awesome project to show the wizard is magic")
        expect(page).to have_field("description", with: "An awesome project to show the wizard is magic")
        select "Research", from: "project_purpose"
        expect(page).not_to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
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
        request = NewProjectRequest.create(requested_by: researcher_user.uid)
        sign_in researcher_user
        visit "/new-project/review-submit/#{request.id}"
        expect(page).to have_content "Take a moment to review"
        expect(page).to have_css("#project_title")
        click_on("Submit")
        within(".project-title") do
          expect(page).to have_content("This field is required.")
        end

        expect(page).to have_content("Please resolve errors before submitting your request")
        # Failed submit re-renders the review page; wait for the form again
        expect(page).to have_css("#project_title")
        fill_in_and_out("project_title", with: "A basic Project")
        expect(page).to have_field("project_title", with: "A basic Project")

        click_on("Submit")
        within(".parent-folder") do
          expect(page).to have_content("This field is required.")
        end

        fill_in :parent_folder, with: "abc_lab"
        click_on("Submit")
        within(".project-folder") do
          expect(page).to have_content("This field is required.")
        end

        # After several validation redirects, re-wait for full review form
        expect(page).to have_content "Take a moment to review"
        expect(page).to have_css("#project_title")
        expect(page).to have_css("#data_sponsor_input")

        fill_in :project_folder, with: "skeletor"
        select "Teaching", from: :project_purpose
        fill_in_and_out("description", with: "An awesome project to show the wizard is magic")
        expect(page).to have_field("description", with: "An awesome project to show the wizard is magic")

        # Prefer "not selected" over not_to have_content: Lux may put department
        # option labels in the DOM when mounted, which makes page text flaky.
        rdss = { code: "77777", name: "RDSS-Research Data and Scholarship Services" }
        hpc = { code: "66666", name: "HPC-High Performance Computing" }
        expect(page).not_to have_field("request[departments][]", type: :hidden, with: rdss.to_json)

        select_and_verify_department(department: rdss[:name], department_code: rdss[:code], department_list: [])
        select_and_verify_department(department: hpc[:name], department_code: hpc[:code], department_list: [rdss])

        select_user(researcher_user, "data_sponsor", "request[data_sponsor]")
        select_user(researcher_user, "data_manager", "request[data_manager]")

        click_on("Submit")
        expect(page).to have_content("Your new project request is submitted")
      end

      it "can not submit if the request has the data sponsor or manager in the data users" do
        Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
        request_project = FactoryBot.create(:request_project, requested_by: researcher_user.uid, data_sponsor: researcher_user.uid, data_manager: researcher_user.uid,
                                                              user_roles: [{ "uid" => researcher_user.uid, "read_only" => true }])
        sign_in researcher_user
        visit "/new-project/review-submit/#{request_project.id}"
        expect(page).to have_content "Take a moment to review"
        click_on("Submit")
        within(".user-input-display") do
          expect(page).to have_content("Data sponsor should not be a data user, Data manager should not be a data user")
        end
      end

      it "saves work in progress if user jumps to another step in the wizard" do
        Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))

        sign_in researcher_user
        visit "/"
        click_on "New Project Request"
        expect(page).to have_content "Tell us a little about your project!"
        # Wait for the form and sidebar save-on-navigate links (wizardNavigation binds on load/turbo:render)
        expect(page).to have_css("#project_title")
        expect(page).to have_css("a.go-to-step", text: "Review and Submit")

        random_title = "Project #{rand(100_000)} title"
        fill_in_and_out("project_title", with: random_title)
        expect(page).to have_field("project_title", with: random_title)

        # Sidebar jump triggers saveOnClick → form POST with redirectUrl, then Review step
        click_on "Review and Submit"
        expect(page).to have_content("Take a moment to review")
        expect(page).to have_field("project_title", with: random_title)
      end

      it "deletes departments when clicking on the X next to them" do
        Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))

        sign_in researcher_user
        visit "/"
        click_on "New Project Request"
        expect(page).to have_content "Tell us a little about your project!"
        expect(page).to have_css("#project_title")
        fill_in_and_out("project_title", with: "A basic Project")
        expect(page).to have_field("project_title", with: "A basic Project")
        fill_in :parent_folder, with: "abc_lab"
        fill_in :project_folder, with: "skeletor"
        fill_in_and_out("description", with: "An awesome project to show the wizard is magic")
        expect(page).to have_field("description", with: "An awesome project to show the wizard is magic")

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
        end.to change { NewProjectRequest.count }.by(1)
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
        end.to change { NewProjectRequest.count }.by(1)
      end

      it "does not allow requests to be submitted with duplicate departments." do
        Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
        sign_in researcher_user
        visit "new-project/project-info"
        expect(page).to have_css(".departments .lux-field input")

        rdss_json = "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}"
        select_and_verify_department(department: "RDSS-Research Data and Scholarship Services", department_code: "77777", department_list: [])
        # Already-selected department should not reappear as a choosable result
        within(".departments") do
          page.find(".lux-field input").fill_in with: "77777"
          # Wait for the filter UI; selected depts are filtered out of the result list
          expect(page).to have_css(".lux-autocomplete-input")
          expect(page).not_to have_css(".lux-autocomplete-result", text: "RDSS-Research Data and Scholarship Services", wait: 2)
        end

        # Exactly one selected department value in the form (not "name appears once in page text" —
        # Lux may still mirror labels elsewhere in the component tree)
        expect(page).to have_field("request[departments][]", type: :hidden, with: rdss_json)
        selected_dept_values = all("input[name='request[departments][]']", visible: :hidden).map(&:value)
        expect(selected_dept_values.count { |v| v == rdss_json }).to eq(1)

        click_on "Review and Submit"
        expect(page).to have_content("Take a moment to review your details and make any necessary edits before finalizing.")
        expect(page).to have_field("request[departments][]", type: :hidden, with: rdss_json)
        selected_dept_values = all("input[name='request[departments][]']", visible: :hidden).map(&:value)
        expect(selected_dept_values.count { |v| v == rdss_json }).to eq(1)

        fill_in :project_title, with: "No Duplicate Departments Project"
        fill_in :parent_folder, with: "abc_lab"
        fill_in :project_folder, with: "skeletor"
        fill_in :description, with: "An awesome project to show the wizard is magic"
        select "Research", from: "project_purpose"
        select_user(researcher_user, "data_sponsor", "request[data_sponsor]")
        select_user(researcher_user, "data_manager", "request[data_manager]")

        click_on "Submit"
        expect(page).to have_content("Your new project request is submitted")

        visit new_project_request_path(NewProjectRequest.last.id)
        expect(page).to have_content("No Duplicate Departments Project")
        expect(page).to have_content("RDSS-Research Data and Scholarship Services")
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
        end.to change { NewProjectRequest.count }.by(1)
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

        # Sometimes the NewProjectRequest is not created yet and it makes the test fail, so let's retry until it is created
        begin
          request = NewProjectRequest.last
          redo if request.nil?
        end

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

        # Sometimes the NewProjectRequest is not created yet and it makes the test fail, so let's retry until it is created
        begin
          request = NewProjectRequest.last
          redo if request.nil?
        end
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

          # Sometimes the NewProjectRequest is not created yet and it makes the test fail, so let's retry until it is created
          begin
            request = NewProjectRequest.last
            redo if request.nil?
          end

          expect(request&.project_title).to eq("Dashboard Redirect Test")
        end.to change { NewProjectRequest.count }.by(1)
      end

      it "preserves the tab order for the request wizard" do
        sign_in researcher_user
        visit "/"
        click_on "New Project Request"

        # Wait for step content and Lux-mounted department field (avoid generated #displayInput-v-*)
        expect(page).to have_content "Tell us a little about your project!"
        expect(page).to have_css("#project_title")
        expect(page).to have_css(".departments .lux-field input")

        # Project Information tab order (stable field ids + department container)
        find("#project_title").click
        expect_active_element_id("project_title")
        send_tab
        expect_active_element_id("parent_folder")
        send_tab
        expect_active_element_id("project_folder")
        send_tab
        expect_active_element_id("project_purpose")
        send_tab
        expect_active_element_id("description")
        send_tab
        expect_focus_within(".departments")

        click_on "Next"
        expect(page).to have_content "Assign roles for your project"
        expect(page).to have_css("#data_sponsor_input input")
        expect(page).to have_css("#data_manager_input input")
        expect(page).to have_css("#add-users")

        # Roles and People tab order (scope Lux inputs by #data_*_input, not displayInput-v-N)
        find("#data_sponsor_input input").click
        expect_focus_within("#data_sponsor_input")
        send_tab
        expect_focus_within("#data_manager_input")
        send_tab
        expect_active_element_id("add-users")

        click_on "Next"
        expect(page).to have_content "Enter the storage and access needs"
        expect(page).to have_css("label[for='radio500gb']")
        expect(page).to have_css("#number_of_files")

        # Storage and Access tab order — prefer for=/id and href over positional .first/.last.
        # Quota radios use tabindex=-1; the visible tab stops are the labels (tabindex=0).
        # Clicking the 500 GB label focuses the associated radio; then tab from that label
        # walks the remaining quota labels (matches browser behavior used historically here).
        quota = find("label[for='radio500gb']")
        quota.click
        expect_active_element_id("radio500gb", visible: :hidden)

        quota.send_keys(:tab)
        expect_focus_within("label[for='radio2tb']")
        find("label[for='radio2tb']").send_keys(:tab)
        expect_focus_within("label[for='radio10tb']")
        find("label[for='radio10tb']").send_keys(:tab)
        expect_focus_within("label[for='radio25tb']")
        find("label[for='radio25tb']").send_keys(:tab)
        expect_focus_within("label[for='radiocustom']")
        find("label[for='radiocustom']").send_keys(:tab)
        expect_active_element_id("number_of_files")
        send_tab
        expect_focus_within("a.storage-tooltip-link[href*='accessing-tigerdata']")
        send_tab
        # Checked radio in each group is the only tab stop (defaults to "no")
        expect_active_element_id("hpc_no")
        send_tab
        expect_active_element_id("network_no")
        send_tab
        expect_focus_within("a.storage-tooltip-link[href*='document/6796']")
        send_tab
        expect_active_element_id("globus_no")
      end
    end
  end
end
