# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Page", connect_to_mediaflux: true, type: :system  do
  # TODO: - When the sponsors have access to write in the system we should remove trainer from here
  # let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "kl37", mediaflux_session: SystemUser.mediaflux_session, trainer: true) }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "puladmin", mediaflux_session: SystemUser.mediaflux_session) }
  let(:superuser) { FactoryBot.create(:superuser, uid: "root", mediaflux_session: SystemUser.mediaflux_session) }
  let!(:data_manager) { FactoryBot.create(:data_manager, uid: "mjc12", mediaflux_session: SystemUser.mediaflux_session) }
  let(:read_only) { FactoryBot.create :user }
  let(:read_write) { FactoryBot.create :user }
  let(:pending_text) do
    "Your new project request is in the queue. Please allow 5 business days for our team to review your needs and set everything up. For assistance, please contact tigerdata@princeton.edu."
  end
  let(:metadata_model) do
    hash = {
      data_sponsor: sponsor_user.uid,
      data_manager: data_manager.uid,
      title: "project 123",
      departments: ["77777"], # RDSS test code in fixture data
      description: "hello world",
      data_user_read_only: [read_only.uid],
      data_user_read_write: [read_write.uid],
      status: ::Project::PENDING_STATUS,
      created_on: Time.current.in_time_zone("America/New_York").iso8601,
      created_by: FactoryBot.create(:user).uid,
      project_id: "10.123/456"
    }
    ProjectMetadata.new_from_hash(hash)
  end
  let(:project_not_in_mediaflux) { FactoryBot.create(:project, metadata_model: metadata_model) }
  let(:mediaflux_id) { 1097 }
  let(:project_in_mediaflux) do
    project_not_in_mediaflux
    project_not_in_mediaflux.metadata_model.status = Project::APPROVED_STATUS
    project_not_in_mediaflux.mediaflux_id = mediaflux_id
    project_not_in_mediaflux.save!
    project_not_in_mediaflux.reload
  end

  before do
    sign_in sponsor_user
    Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
  end

  context "Show page" do
    context "Before it is in MediaFlux" do
      it "Shows the not yet approved (pending) project" do
        sign_in sponsor_user
        visit "/projects/#{project_not_in_mediaflux.id}/details"
        expect(page).to have_content pending_text
      end
    end

    context "when the data user is empty" do
      let(:metadata_model) do
        hash = {
          data_sponsor: sponsor_user.uid,
          data_manager: data_manager.uid,
          project_directory: "project-123",
          title: "project 123",
          departments: ["RDSS"],
          description: "hello world",
          data_user_read_only: [],
          data_user_read_write: [],
          project_id: "abc-123",
          storage_capacity: { size: { requested: "100" }, unit: { requested: "TB" } }.with_indifferent_access,
          storage_performance_expectations: { requested: "Standard" },
          project_purpose: "Research",
          status: ::Project::PENDING_STATUS,
          created_on: Time.current.in_time_zone("America/New_York").iso8601,
          created_by: FactoryBot.create(:user).uid
        }
        ProjectMetadata.new_from_hash(hash)
      end

      it "shows none when the data user is empty" do
        sign_in data_manager
        visit "/projects/#{project_not_in_mediaflux.id}/details"
        expect(page).to have_content "This project has not been saved to Mediaflux"
        expect(page).to have_content pending_text
        expect(page).not_to have_button "Approve Project"
        expect(page).to have_content "Data Users\nNone"
        expect(page).to have_content "Project ID\nabc-123"
        expect(page).to have_content "Storage Capacity (Requested)\n100 TB"
        expect(page).to have_content "Storage Performance Expectations (Requested)\nStandard"
        expect(page).to have_content "Project Purpose\nResearch"
        expect(page).to be_axe_clean
          .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
          .skipping(:'color-contrast')
      end
    end
  end

  context "Edit page" do
    context "a project is still pending" do
      it "redirects the user to the project details page and flashes a message" do
        sign_in sponsor_user
        visit "/projects/#{project_not_in_mediaflux.id}/edit"

        expect(page).to have_content(project_not_in_mediaflux.title)
        expect(page).to have_content("Pending projects can not be edited.")
      end
    end

    context "a project is active" do
      before do
        sign_in sponsor_user
        project_in_mediaflux.metadata_json["status"] = Project::APPROVED_STATUS
        project_in_mediaflux.save!
        visit "/projects/#{project_in_mediaflux.id}/edit"
      end

      it "redirects the user to the project details page if the user is not a sponsor or manager" do
        sign_in read_only
        # project_in_mediaflux.metadata_json["status"] = Project::APPROVED_STATUS
        # project_in_mediaflux.save!
        visit "/projects/#{project_in_mediaflux.id}/edit"

        expect(page).to have_content(project_not_in_mediaflux.title)
        expect(page).to have_content("Only data sponsors and data managers can revise this project.")
      end

      # TODO: Project edit is not really working since we are not pushing the value to Mediaflux.
      # By the looks of it the code is not saving the changes in the Rails DB either.
      # See https://github.com/pulibrary/tigerdata-app/issues/1608
      xit "preserves the readonly directory field" do
        click_on "Submit"
        project_in_mediaflux.reload
        expect(project_in_mediaflux.metadata[:project_directory]).to eq "project-123"
      end

      it "prevents sponsor users from editing the directory field" do
        expect(page.find_all("#project_directory[readonly]").count).to eq(1)
      end

      it "loads existing Data Sponsor" do
        expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
      end

      # TODO: Project edit is not really working since we are not pushing the value to Mediaflux.
      # By the looks of it the code is not saving the changes in the Rails DB either.
      # See https://github.com/pulibrary/tigerdata-app/issues/1608
      xit "redirects the user to the revision request confirmation page upon submission" do
        page.save_screenshot
        click_on "Submit"
        page.save_screenshot
        project_in_mediaflux.reload
        expect(project_in_mediaflux.metadata[:project_directory]).to eq "project-123"

        # This is the confirmation page. It needs a button to return to the dashboard
        # and it needs to be_axe_clean.
        expect(page).to have_content "Project Revision Request Received"
        expect(page).to have_link "Return to Dashboard"
        expect(page).to be_axe_clean
          .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
          .skipping(:'color-contrast')
        click_on "Return to Dashboard"
        expect(page).to have_content "Sponsor"
      end
    end

    context "upon cancelation" do
      before do
        sign_in sponsor_user
        project_in_mediaflux.metadata_json["status"] = Project::APPROVED_STATUS
        project_in_mediaflux.save!
        visit "/projects/#{project_in_mediaflux.id}/edit"
      end

      it "redirects the user back to the project show page" do
        click_on "Cancel"
        expect(page).to have_content(project_in_mediaflux.title)
      end
    end

    context "when authenticated as a superuser" do
      context "when the project is not persisted within Mediaflux" do
        before do
          project_not_in_mediaflux
          project_not_in_mediaflux.metadata_model.status = Project::APPROVED_STATUS
          project_not_in_mediaflux.save!
          project_not_in_mediaflux.reload

          sign_in superuser

          visit "/projects/#{project_not_in_mediaflux.id}/edit"
        end

        it "permits superusers to edit the directory field" do
          expect(page.find_all("#project_directory[readonly]").count).to eq(0)
        end
      end
    end

    context "when authenticated as a sysadmin user" do
      context "when the project is not persisted within Mediaflux" do
        before do
          project_not_in_mediaflux
          project_not_in_mediaflux.metadata_model.status = Project::APPROVED_STATUS
          project_not_in_mediaflux.save!
          project_not_in_mediaflux.reload

          sign_in sysadmin_user

          visit "/projects/#{project_not_in_mediaflux.id}/edit"
        end

        it "permits sysadmin users to edit the directory field" do
          expect(page.find_all("#project_directory[readonly]").count).to eq(0)
        end
      end
    end
  end

  context "Create page" do
    before do
      # make sure the users exist before the page loads
      data_manager
      read_only
      read_write
    end

    it "allows the user to create a project" do
      sign_in sponsor_user
      visit dashboard_path
      click_on "Create new project"
      expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
      fill_in_and_out "data_manager", with: data_manager.uid
      # select a department
      select "Research Data and Scholarship Services", from: "departments"
      fill_in "project_directory", with: "test_project"
      fill_in "title", with: "My test project"
      expect(page).to have_content("tigerdata/")
      expect do
        expect(page.find_all("input:invalid").count).to eq(0)
        click_on "Submit"
        # For some reason the above click on submit sometimes does not submit the form
        #  even though the inputs are all valid, so try it again...
        if page.find_all("#btn-add-rw-user").count > 0
          click_on "Submit"
        end
        # expect(page).to have_content("New Project Request Received", wait: 20)
      end.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1).times
      # This is the confirmation page. It needs a button to return to the dashboard
      # and it needs to be_axe_clean.
      expect(page).to have_content "New Project Request Received"
      expect(page).to have_link "Return to Dashboard"
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
        .skipping(:'color-contrast')
      click_on "Return to Dashboard"
      expect(page).to have_content "Sponsor"
      find(:xpath, "//a[text()='My test project']").click
      click_on "Details"
      # defaults have been applied
      expect(page).to have_content "Storage Capacity (Requested)\n500 GB"
      expect(page).to have_content "Storage Performance Expectations (Requested)\nStandard"
      expect(page).to have_content "Project Purpose\nResearch"
      # project id has been set
      expect(page).to have_content "Project ID\n10.34770/tbd"
    end

    context "data users (read-only and read-write)" do
      it "allows user to enter data users (read-only)" do
        sign_in sponsor_user
        visit dashboard_path
        click_on "Create new project"
        expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
        fill_in_and_out "data_manager", with: data_manager.uid
        click_on "Add User(s)"
        fill_in_and_out "data-user-uid-to-add", with: read_only.uid
        click_on "Save changes"
        select "Research Data and Scholarship Services", from: "departments"
        fill_in "project_directory", with: "test_project"
        fill_in "title", with: "My test project"
        expect(page).to have_content(Rails.configuration.mediaflux["api_root"])
        click_on "Submit"
        click_on "Return to Dashboard"
        find(:xpath, "//a[text()='My test project']").click
        expect(page).to have_content "My test project"
        click_on "Details"
        expect(page).to have_content read_only.display_name + " (read only)"
      end

      it "allows user to enter data users (read-write)" do
        sign_in sponsor_user
        visit dashboard_path
        click_on "Create new project"
        expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
        fill_in_and_out "data_manager", with: data_manager.uid
        click_on "Add User(s)"
        fill_in_and_out "data-user-uid-to-add", with: read_write.uid
        click_on "Save changes"
        find(:xpath, "//*[@id='data_user_1_rw']").click # make user read-write
        select "Research Data and Scholarship Services", from: "departments"
        fill_in "project_directory", with: "test_project"
        fill_in "title", with: "My test project"
        expect(page).to have_content(Rails.configuration.mediaflux["api_root"])
        click_on "Submit"
        click_on "Return to Dashboard"
        find(:xpath, "//a[text()='My test project']").click
        expect(page).to have_content "My test project"
        click_on "Details"
        expect(page).to have_content read_write.display_name
      end

      it "validates that the user entered is valid" do
        sign_in sponsor_user
        visit dashboard_path
        click_on "Create new project"
        expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
        fill_in_and_out "data_manager", with: data_manager.uid
        expect(page).to have_content "No Data User(s) added"

        # Launch the modal, trigger the validation, and then add a valid user
        click_on "Add User(s)"
        fill_in_and_out "data-user-uid-to-add", with: "notuser"
        expect(page.find("#data-user-uid-to-add_error").text).to eq "Invalid value entered"
        fill_in_and_out "data-user-uid-to-add", with: read_only.uid
        expect(page.find("#data-user-uid-to-add_error", visible: false).text).to eq ""
        click_on "Save changes"

        # Launch the modal again and this time don't add any users
        # (but we already had added some so we don't expect the "no data users" message)
        click_on "Add User(s)"
        click_on "Save changes"
        expect(page).not_to have_content "No Data User(s) added"
      end
    end

    context "when a department has not been selected" do
      it "does not allow the user to create a project" do
        sign_in sponsor_user
        visit dashboard_path
        click_on "Create new project"
        expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
        fill_in "project_directory", with: "test_project"
        fill_in "title", with: "My test project"
        expect(page).to have_content(Rails.configuration.mediaflux["api_root"])
        expect do
          click_on "Submit"
        end.not_to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1).times
      end
    end

    context "with an invalid data manager" do
      it "does not allow the user to create a project" do
        sign_in sponsor_user
        visit dashboard_path
        click_on "Create new project"
        expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
        fill_in_and_out "data_manager", with: "xxx"
        expect(page.find("#data_manager_error").text).to eq "Invalid value entered"
        fill_in_and_out "data_manager", with: ""
        expect(page.find("#data_manager_error").text).to eq "This field is required"
        fill_in "project_directory", with: "test_project"
        fill_in "title", with: "My test project"
        expect(page).to have_content(Rails.configuration.mediaflux["api_root"])
        expect(page.find("button[value=Submit]")).to be_disabled
      end
    end

    context "upon cancelation" do
      it "redirects the user back to the dashboard" do
        sign_in sponsor_user
        visit dashboard_path
        click_on "Create new project"
        expect(page).to have_content("New Project Request")
        click_on "Cancel"

        # For some reason the above click on cancel sometimes does not cancel the form
        #  so try it again...
        if page.find_all("#btn-add-rw-user").count > 0
          click_on "Cancel"
        end

        expect(page).to have_content("Welcome, #{sponsor_user.given_name}!")
      end
    end
    context "when the directory name has invalid characters" do
      it "allows the user to create a project" do
        sign_in sponsor_user
        visit dashboard_path
        click_on "Create new project"
        # Data Sponsor is automatically populated.
        fill_in_and_out "data_manager", with: data_manager.uid
        fill_in "project_directory", with: "test?project"
        valid = page.find("input#project_directory:invalid")
        expect(valid).to be_truthy
        fill_in "title", with: "My test project"
        expect(page).to have_content(Rails.configuration.mediaflux["api_root"])
        expect(page).to have_content("New Project")
      end
    end

    context "when the description is empty", connect_to_mediaflux: true do
      it "allows the projects to be created in the Rails database" do
        sign_in sponsor_user
        visit dashboard_path
        click_on "Create new project"
        expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
        fill_in_and_out "data_manager", with: data_manager.uid
        select "Research Data and Scholarship Services", from: "departments"
        project_directory = FFaker::Name.name.tr(" ", "_")
        fill_in "project_directory", with: project_directory
        fill_in "title", with: "My test project"
        expect(page).to have_content(Rails.configuration.mediaflux["api_root"])
        expect(page.find_all("input:invalid").count).to eq(0)
        click_on "Submit"
        # For some reason the above click on submit sometimes does not submit the form
        #  even though the inputs are all valid, so try it again...
        if page.find_all("#btn-add-rw-user").count > 0
          click_on "Submit"
        end
        expect(page).to have_content "New Project Request Received"
      end
    end

    context "when an error is encountered while trying to enqueue the ActiveJob for the TigerdataMailer" do
      let(:mailer) { double(ActionMailer::Parameterized::Mailer) }
      let(:message_delivery) { instance_double(ActionMailer::Parameterized::MessageDelivery) }
      let(:error_message) { "Connection refused - connect(2) for 127.0.0.1:6379" }
      let(:flash_message) do
        "We are sorry, while the project was successfully created, an error was encountered which prevents the delivery of an e-mail message confirming this. " \
          "Please know that this error has been logged, and shall be reviewed by members of RDSS."
      end

      before do
        allow(Honeybadger).to receive(:notify)
        allow(message_delivery).to receive(:deliver_later).and_raise(RedisClient::CannotConnectError, error_message)
        allow(mailer).to receive(:project_creation).and_return(message_delivery)
        allow(TigerdataMailer).to receive(:with).and_return(mailer)
      end

      it "logs the error message, flashes a notification to the end-user, and renders the New Project View" do
        sign_in sponsor_user
        visit dashboard_path
        click_on "Create new project"
        expect(page).to be_axe_clean
          .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
          .skipping(:'color-contrast')

        expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
        fill_in_and_out "data_manager", with: data_manager.uid
        select "Research Data and Scholarship Services", from: "departments"
        fill_in "project_directory", with: FFaker::Name.name.tr(" ", "_")
        fill_in "title", with: "My test project"
        expect(page).to have_content(Rails.configuration.mediaflux["api_root"])
        invalid_fields = page.find_all("input:invalid").count
        # There seemed to be some cases where this might fail when run with a headless Chrome browser
        # Inserting a delay ensured that this did not occur at all
        sleep(0.1)
        expect(invalid_fields).to eq(0)
        click_on "Submit"
        # For some reason the above click on submit sometimes does not submit the form
        #  even though the inputs are all valid, so try it again...
        if page.find_all("#btn-add-rw-user").count > 0
          click_on "Submit"
        end
        new_project = Project.last
        expect(new_project).not_to be nil
        expect(page).not_to have_content "New Project Request Received"
        expect(page).to have_content flash_message

        expect(Honeybadger).to have_received(:notify).with(kind_of(TigerData::MailerError), context: {
                                                             current_user_email: sponsor_user.email,
                                                             project_id: new_project.id,
                                                             project_metadata: new_project.metadata
                                                           })
      end
    end
  end

  context "Index page" do
    before do
      project_not_in_mediaflux
    end

    it "shows the existing projects" do
      sign_in sponsor_user
      visit "/projects"
      expect(page).to have_content(project_not_in_mediaflux.title)
    end
  end

  context "Approve page" do
    let(:project) { project_not_in_mediaflux }
    let(:custom_directory) { "new-project/dir/example-project-#{Time.now.utc.iso8601.tr(':', '-')}-#{rand(1..100_000)}" }

    it "renders the form with the Mediaflux ID" do
      sign_in sysadmin_user
      expect(project.mediaflux_id).to be nil
      expect(project.metadata_json["status"]).to eq Project::PENDING_STATUS

      visit project_approve_path(project)
      expect(page).to have_content("Project Approval: #{project.metadata_json['title']}")
      select "Other", from: "event_note"
      fill_in "event_note_message", with: "Note from sysadmin"
      fill_in "project_directory", with: custom_directory
      click_on "Approve"
      expect(page).to have_content("Project Approval Received")

      project.reload
      expect(project.mediaflux_id).not_to be nil
      expect(project.metadata_json["status"]).to eq Project::APPROVED_STATUS
      expect(project.project_directory).to eq("tigerdata/#{custom_directory}")
    end

    it "redirects the user to the project approval confirmation page upon submission", js: true do
      sign_in sysadmin_user
      expect(project.mediaflux_id).to be nil
      expect(project.metadata_json["status"]).to eq Project::PENDING_STATUS
      visit project_approve_path(project)
      expect(page).to have_content("Project Approval: #{project.metadata_json['title']}")
      expect(page).to have_content(Rails.configuration.mediaflux["api_root"])
      expect(page).to have_content(project.project_directory_short)

      fill_in "storage_capacity", with: 500
      select "GB", from: "storage_unit"
      fill_in "project_directory", with: custom_directory

      select "Other", from: "event_note"
      fill_in "event_note_message", with: "Note from sysadmin"
      click_on "Approve"

      # This is the confirmation page. It needs a button to return to the dashboard
      # and it needs to be_axe_clean.
      expect(page).to have_content "Project Approval Received"
      expect(page).to have_link "Return to Dashboard"

      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
        .skipping(:'color-contrast')

      click_on "Return to Dashboard"
      click_on "Administration"
      expect(page).to have_content "Pending Projects"
    end
  end

  context "GET /projects/:id" do
    context "when authenticated" do
      let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
      let(:completion_time) { Time.current.in_time_zone("America/New_York").iso8601 }
      let(:approved_project) do
        project = FactoryBot.create(:approved_project, title: "project 111", data_sponsor: sponsor_user.uid)
        project.mediaflux_id = nil
        project
      end

      before do
        sign_in sponsor_user
        # Save the project in mediaflux
        approved_project.save_in_mediaflux(user: sponsor_user)
        # Create file(s) for the project in mediaflux using test asset create request
        Mediaflux::TestAssetCreateRequest.new(session_token: sponsor_user.mediaflux_session, parent_id: approved_project.mediaflux_id, pattern: "SampleFile.txt").resolve
        Mediaflux::TestAssetCreateRequest.new(session_token: sponsor_user.mediaflux_session, parent_id: approved_project.mediaflux_id, count: 3, pattern: "RandomFile.txt").resolve
      end

      context "when the Mediaflux assets have one or multiple files" do
        it "enqueues a Sidekiq job for asynchronously requesting project files" do
          visit project_path(approved_project)

          expect(page).to have_content("Download Complete List")
          click_on "Download Complete List"
          expect(page).to have_content("This will generate a list of 4 files and their attributes in a downloadable CSV. Do you wish to continue?")
          expect(page).to have_content("Yes")
          sleep 1
          click_on "Yes"
          expect(page).to have_content("File list for \"#{approved_project.title}\" is being generated in the background.")
          expect(sponsor_user.user_requests.count).to eq(1)
          expect(sponsor_user.user_requests.first.job_id).not_to be nil
          expect(sponsor_user.user_requests.first.state).to eq FileInventoryRequest::PENDING
          expect(sponsor_user.user_requests.first.type).to eq "FileInventoryRequest"
        end
      end

      context "when the quota is allocated" do
        let(:storage_capacity) do
          {
            size: { requested: 500, approved: 500 },
            unit: { requested: "GB", approved: "GB" }
          }.with_indifferent_access
        end
        let(:storage_performance_expectations) do
          {
            requested: "Standard",
            approved: "performant"
          }.with_indifferent_access
        end
        let(:metadata_model) do
          hash = {
            data_sponsor: sponsor_user.uid,
            data_manager: data_manager.uid,
            project_directory: "tigerdata/#{random_project_directory}",
            title: "project 123",
            departments: ["RDSS"],
            description: "hello world",
            data_user_read_only: [read_only.uid],
            data_user_read_write: [read_write.uid],
            status: ::Project::APPROVED_STATUS,
            created_on: Time.current.in_time_zone("America/New_York").iso8601,
            created_by: FactoryBot.create(:user).uid,
            project_id: random_project_id,
            storage_capacity: storage_capacity,
            storage_performance_expectations: storage_performance_expectations,
            project_purpose: "Research"
          }
          ProjectMetadata.new_from_hash(hash)
        end

        let(:approved_project) do
          persisted = FactoryBot.create(:approved_project, metadata_model: metadata_model)
          persisted.mediaflux_id = nil
          persisted
        end

        before do
          sign_in sponsor_user
          # Save the project in mediaflux
          approved_project.save_in_mediaflux(user: sponsor_user)
        end

        it "renders the storage capacity in the show view" do
          visit project_path(approved_project)

          expect(page).to have_content "Storage (500.000 GB)"
          expect(page).to have_content "400 bytes out of 500 GB used"
          expect(page).to be_axe_clean
            .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
            .skipping(:'color-contrast')
        end

        context "when requesting the XML for a project" do
          before do
            visit project_path(approved_project, params: { format: "xml" })
          end

          it "returns the XML with the correct attributes" do
            xml = page.body
            expect(xml).to include("<projectDirectoryPath protocol=\"NFS\">#{approved_project.project_directory}</projectDirectoryPath>")
            expect(xml).to include("<title inherited=\"false\" discoverable=\"true\" trackingLevel=\"ResourceRecord\">#{approved_project.title}</title>")
            # NOTE: 500 GB are available, hence the request was approved
            expect(xml).to include("<storageCapacity approved=\"true\" inherited=\"false\" discoverable=\"false\" trackingLevel=\"InternalUseOnly\"/>")
            expect(xml).to include("<storagePerformance inherited=\"false\" discoverable=\"false\" trackingLevel=\"InternalUseOnly\" approved=\"true\">")
            expect(xml).to include("<requestedValue>Standard</requestedValue>")
            expect(xml).to include("</storagePerformance>")
            expect(xml).to include("<projectPurpose inherited=\"true\" discoverable=\"true\" trackingLevel=\"InternalUseOnly\">Research</projectPurpose>")
          end
        end
      end
    end
  end
end
