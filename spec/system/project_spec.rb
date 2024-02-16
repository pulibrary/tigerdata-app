# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Page", type: :system, stub_mediaflux: true do
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123") }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "puladmin") }
  let(:data_manager) { FactoryBot.create(:user, uid: "pul987") }
  let(:read_only) { FactoryBot.create :user }
  let(:read_write) { FactoryBot.create :user }
  let(:pending_text) do
    "Your new project request is in the queue. Please allow 5 business days for our team to review your needs and set everything up. For assistance, please contact tigerdata@princeton.edu."
  end
  let(:metadata) do
    {
      data_sponsor: sponsor_user.uid,
      data_manager: data_manager.uid,
      directory: "project-123",
      title: "project 123",
      departments: ["RDSS"],
      description: "hello world",
      data_user_read_only: [read_only.uid],
      data_user_read_write: [read_write.uid],
      status: ::Project::PENDING_STATUS
    }
  end

  let(:project_not_in_mediaflux) { FactoryBot.create(:project, metadata: metadata) }
  let(:project_in_mediaflux) { project_not_in_mediaflux }

  before do
    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
      .with(
        body: /<service name="asset.namespace.create" session="test-session-token">/
      ).to_return(status: 200, body: "<xml>something</xml>")

    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
      .with(
        body: /<service name="asset.create" session="test-session-token">/
      ).to_return(status: 200, body: "<?xml version=\"1.0\" ?> <response> <reply type=\"result\"> <result> <id>999</id> </result> </reply> </response>")

    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
      .with(
        body: /<service name="asset.set" session="test-session-token">/
      ).to_return(status: 200, body: "<?xml version=\"1.0\" ?> <response> <reply type=\"result\"> <result> <id>999</id> </result> </reply> </response>")

    sign_in sponsor_user
  end

  context "Show page" do
    context "Before it is in MediaFlux" do
      it "Shows the not yet approved (pending) project" do
        sign_in sponsor_user
        visit "/projects/#{project_not_in_mediaflux.id}"
        expect(page).to have_content "(#{::Project::PENDING_STATUS})"
        expect(page).to have_content pending_text
      end
    end

    context "when the data user is empty" do
      let(:metadata) do
        {
          data_sponsor: sponsor_user.uid,
          data_manager: data_manager.uid,
          directory: "project-123",
          title: "project 123",
          departments: ["RDSS"],
          description: "hello world",
          data_user_read_only: [],
          data_user_read_write: [],
          project_id: "abc-123",
          storage_capacity_requested: "100 TB",
          storage_performance_expectations_requested: "Standard",
          project_purpose: "Research"
        }
      end

      it "shows none when the data user is empty" do
        sign_in data_manager
        visit "/projects/#{project_not_in_mediaflux.id}"
        expect(page).to have_content "project 123 (#{::Project::PENDING_STATUS})"
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

        expect(page).to have_content("Project Details: #{project_not_in_mediaflux.title}")
        expect(page).to have_content("Pending projects can not be edited.")
      end
    end
    context "a project is active" do
      it "redirects the user to the project details page if the user is not a sponsor or manager" do
        sign_in read_only
        project_in_mediaflux.metadata_json["status"] = Project::APPROVE_STATUS
        project_in_mediaflux.save!
        visit "/projects/#{project_in_mediaflux.id}/edit"

        expect(page).to have_content("Project Details: #{project_not_in_mediaflux.title}")
        expect(page).to have_content("Only data sponsors and data managers can revise this project.")
      end

      before do
        sign_in sponsor_user
        project_in_mediaflux.metadata_json["status"] = Project::APPROVE_STATUS
        project_in_mediaflux.save!
        visit "/projects/#{project_in_mediaflux.id}/edit"
      end
      it "preserves the readonly directory field" do
        click_on "Submit"
        project_in_mediaflux.reload
        expect(project_in_mediaflux.metadata[:directory]).to eq "project-123"
      end
      it "loads existing Data Sponsor" do
        expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
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
      visit "/"
      click_on "New Project"
      expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
      fill_in "data_manager", with: data_manager.uid
      fill_in "ro-user-uid-to-add", with: read_only.uid
      # Without removing the focus from the form field, the "change" event is not propagated for the DOM
      page.find("body").click
      click_on "btn-add-ro-user"
      fill_in "rw-user-uid-to-add", with: read_write.uid
      # Without removing the focus from the form field, the "change" event is not propagated for the DOM
      page.find("body").click
      click_on "btn-add-rw-user"
      fill_in "directory", with: "test_project"
      fill_in "title", with: "My test project"
      expect(page).to have_content("Project Directory: /td-test-001/")
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
      expect(page).to have_button "Return to Dashboard"
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
        .skipping(:'color-contrast')
      click_on "Return to Dashboard"
      expect(page).to have_content "Sponsored by Me"
      click_on("My test project")
      # defaults have been applied
      expect(page).to have_content "Storage Capacity (Requested)\n500 GB"
      expect(page).to have_content "Storage Performance Expectations (Requested)\nStandard"
      expect(page).to have_content "Project Purpose\nResearch"
      # project id has been set
      expect(page).to have_content "Project ID\n10.34770/tbd"
    end

    context "with an invalid data manager" do
      it "does not allow the user to create a project" do
        sign_in sponsor_user
        visit "/"
        click_on "New Project"
        expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
        fill_in "data_manager", with: "xxx"
        expect(page.find("#data_manager").native.attribute("validationMessage")).to eq "Please select a valid value."
        fill_in "ro-user-uid-to-add", with: read_only.uid
        # Without removing the focus from the form field, the "change" event is not propagated for the DOM
        page.find("body").click
        click_on "btn-add-ro-user"
        fill_in "rw-user-uid-to-add", with: read_write.uid
        # Without removing the focus from the form field, the "change" event is not propagated for the DOM
        page.find("body").click
        click_on "btn-add-rw-user"
        fill_in "directory", with: "test_project"
        fill_in "title", with: "My test project"
        expect(page).to have_content("Project Directory: /td-test-001/")
        expect(page.find("button[value=Submit]")).to be_disabled
      end
    end

    context "with an invalid data users" do
      it "does not allow the user to create a project" do
        sign_in sponsor_user
        visit "/"
        click_on "New Project"
        expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
        fill_in "data_manager", with: data_manager.uid
        fill_in "ro-user-uid-to-add", with: "xxx"
        page.find("body").click
        expect(page.find("#ro-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."

        fill_in "rw-user-uid-to-add", with: "zzz"
        page.find("body").click
        expect(page.find("#ro-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."
        fill_in "directory", with: "test_project"
        fill_in "title", with: "My test project"
        expect(page).to have_content("Project Directory: /td-test-001/")
        expect do
          click_on "Submit"
        end.not_to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1).times
      end
    end
    context "upon cancelation" do
      it "redirects the user back to the dashboard" do
        sign_in sponsor_user
        visit "/"
        click_on "New Project"
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
        visit "/"
        click_on "New Project"
        # Data Sponsor is automatically populated.
        fill_in "data_manager", with: data_manager.uid
        fill_in "ro-user-uid-to-add", with: read_only.uid
        page.find("body").click
        click_on "btn-add-ro-user"
        fill_in "rw-user-uid-to-add", with: read_write.uid
        page.find("body").click
        click_on "btn-add-rw-user"
        fill_in "directory", with: "test?project"
        valid = page.find("input#directory:invalid")
        expect(valid).to be_truthy
        fill_in "title", with: "My test project"
        expect(page).to have_content("Project Directory: /td-test-001/")
        expect(page).to have_content("New Project")
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
      expect(page).to have_content("(#{::Project::PENDING_STATUS})")
    end
  end

  context "Approve page" do
    let(:mediaflux_id) { 1234 }
    let(:project) { project_not_in_mediaflux }

    it "renders the form for providing the Mediaflux ID" do
      sign_in sysadmin_user
      expect(project.mediaflux_id).to be nil
      expect(project.metadata_json["status"]).to eq Project::PENDING_STATUS

      visit project_approve_path(project)
      expect(page).to have_content("Project Approval: #{project.metadata_json['title']}")

      fill_in "mediaflux_id", with: mediaflux_id
      click_on "Approve"

      project.reload
      expect(project.mediaflux_id).to eq(mediaflux_id)
      expect(project.metadata_json["status"]).to eq Project::APPROVE_STATUS

      # redirects the user to the project show page
    end
  end

  context "Requesting all files for a given project" do
    context "when authenticated" do
      let(:job_id) { "d3b8eeb4-9c58-4af1-aaaf-7476f2804a44" }
      let(:job) { instance_double(ListProjectContentsJob) }

      before do
        stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
          .with(
                 body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.get\" session=\"test-session-token\">\n    <args>\n      <id/>\n    </args>\n  </service>\n</request>\n"
               ).to_return(status: 200, body: "<?xml version=\"1.0\" ?> <response> <reply type=\"result\"> <result> <id>999</id> </result> </reply> </response>")

        allow(ListProjectContentsJob).to receive(:perform_later).and_return(job)
        allow(job).to receive(:job_id).and_return(job_id)

        sign_in sponsor_user
      end

      it "enqueues a Sidekiq job for asynchronously requesting project files" do
        visit project_contents_path(project_not_in_mediaflux)
        expect(page).to have_content("List All Files")
        click_on "List All Files"
        expect(page).to have_content("This will generate a list of 1,234,567 files and their attributes in a downloadable CSV. Do you wish to continue?")
        expect(page).to have_content("Yes")
        click_on "Yes"
        expect(page).to have_content("You have a background job running.")
        expect(sponsor_user.user_jobs).not_to be_empty
        user_job = sponsor_user.user_jobs.first
        expect(user_job.job_id).to eq(job.job_id)
      end
    end
  end
end
