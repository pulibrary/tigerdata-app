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

  context "GET /projects/:id" do
    context "when authenticated" do
      let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
      let(:completion_time) { Time.current.in_time_zone("America/New_York").iso8601 }
      let(:approved_project) do
        project = FactoryBot.create(:approved_project, title: "project 111", data_sponsor: sponsor_user.uid)
        project.mediaflux_id = nil
        project.approve!(current_user: sponsor_user)
        project
      end

      before do
        sign_in sponsor_user
        # Create file(s) for the project in mediaflux using test asset create request
        Mediaflux::TestAssetCreateRequest.new(session_token: sponsor_user.mediaflux_session, parent_id: approved_project.mediaflux_id, pattern: "SampleFile.txt").resolve
        Mediaflux::TestAssetCreateRequest.new(session_token: sponsor_user.mediaflux_session, parent_id: approved_project.mediaflux_id, count: 3, pattern: "RandomFile.txt").resolve
      end

      context "when the Mediaflux assets have one or multiple files" do
        it "enqueues a Sidekiq job for asynchronously requesting project files",
        :integration do
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
          persisted.approve!(current_user: sponsor_user)
          persisted
        end

        it "renders the storage capacity in the show view",
        :integration do
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

          it "returns the XML with the correct attributes",
          :integration do
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
