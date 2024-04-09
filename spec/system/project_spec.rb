# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Page", type: :system, stub_mediaflux: true do
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123") }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "puladmin") }
  let!(:data_manager) { FactoryBot.create(:data_manager, uid: "pul987") }
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
  let(:mediaflux_id) { 1097 }
  let(:project_in_mediaflux) do
    project_not_in_mediaflux
    project_not_in_mediaflux.metadata_json["status"] = Project::APPROVE_STATUS
    project_not_in_mediaflux.mediaflux_id = mediaflux_id
    project_not_in_mediaflux.save!
    project_not_in_mediaflux.reload
  end

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
        #project_in_mediaflux.metadata_json["status"] = Project::APPROVE_STATUS
        #project_in_mediaflux.save!
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

      it "redirects the user to the revision request confirmation page upon submission" do
        click_on "Submit"
        project_in_mediaflux.reload
        expect(project_in_mediaflux.metadata[:directory]).to eq "project-123"

        # This is the confirmation page. It needs a button to return to the dashboard
        # and it needs to be_axe_clean.
        expect(page).to have_content "Project Revision Request Received"
        expect(page).to have_button "Return to Dashboard"
        expect(page).to be_axe_clean
          .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
          .skipping(:'color-contrast')
        click_on "Return to Dashboard"
        expect(page).to have_content "Sponsored by Me"
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
      #select a department
      select 'RDSS', :from => 'departments'
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

    context "when a department has not been selected" do
      it "does not allow the user to create a project" do
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
        click_on "Submit"
      end.not_to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1).times
      end
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

    context "when the description is empty" do
      before do
        @original_api_host = Rails.configuration.mediaflux["api_host"]
        Rails.configuration.mediaflux["api_host"] = "0.0.0.0"
        @session_id = sponsor_user.mediaflux_session
      end

      after do
        Rails.configuration.mediaflux["api_host"] = @original_api_host
      end

      it "allows the projects to be created" do

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
        select "RDSS", from: 'departments'
        fill_in "directory", with: FFaker::Name.name.gsub(" ","_")
        fill_in "title", with: "My test project"
        expect(page).to have_content("Project Directory: /td-test-001/")
        expect(page.find_all("input:invalid").count).to eq(0)
        click_on "Submit"
        # For some reason the above click on submit sometimes does not submit the form
        #  even though the inputs are all valid, so try it again...
        if page.find_all("#btn-add-rw-user").count > 0
          click_on "Submit"
        end
        expect(page).to have_content "New Project Request Received"
        project = Project.last
        project.mediaflux_id = ProjectMediaflux.create!(project:, session_id: @session_id)
        expect(project.mediaflux_id).not_to be_nil
        expect(Mediaflux::Http::DestroyAssetRequest.new(session_token: @session_id, collection: project.mediaflux_id, members: true).error?).to be_falsey
      end
    end

    context "when an error is encountered while trying to enqueue the ActiveJob for the TigerdataMailer" do
      let(:mailer) { double(ActionMailer::Parameterized::Mailer) }
      let(:message_delivery) { instance_double(ActionMailer::Parameterized::MessageDelivery) }
      let(:error_message) { "Connection refused - connect(2) for 127.0.0.1:6379" }
      let(:flash_message) { "We are sorry, while the project was successfully created, an error was encountered which prevents the delivery of an e-mail message confirming this. Please know that this error has been logged, and shall be reviewed by members of RDSS." }

      before do
        allow(Honeybadger).to receive(:notify)
        allow(message_delivery).to receive(:deliver_later).and_raise(RedisClient::CannotConnectError, error_message)
        allow(mailer).to receive(:project_creation).and_return(message_delivery)
        allow(TigerdataMailer).to receive(:with).and_return(mailer)
      end

      it "logs the error message, flashes a notification to the end-user, and renders the New Project View" do
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
        select "RDSS", from: 'departments'
        fill_in "directory", with: FFaker::Name.name.gsub(" ","_")
        fill_in "title", with: "My test project"
        expect(page).to have_content("Project Directory: /td-test-001/")
        sleep 1
        expect(page.find_all("input:invalid").count).to eq(0)
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

    it "redirects the user to the revision request confirmation page upon submission" do
      sign_in sysadmin_user
      expect(project.mediaflux_id).to be nil
      expect(project.metadata_json["status"]).to eq Project::PENDING_STATUS

      visit project_approve_path(project)
      expect(page).to have_content("Project Approval: #{project.metadata_json['title']}")

      fill_in "mediaflux_id", with: mediaflux_id
      click_on "Approve"

      # This is the confirmation page. It needs a button to return to the dashboard
      # and it needs to be_axe_clean.
      expect(page).to have_content "Project Approval Received"
      expect(page).to have_button "Return to Dashboard"
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
        .skipping(:'color-contrast')
      click_on "Return to Dashboard"
      expect(page).to have_content "Approved Projects"
    end
  end

  context "GET /projects/:id/content" do
    context "when authenticated" do
      let(:completion_time) { Time.current.in_time_zone("America/New_York").iso8601 }

      let(:mediaflux_asset_get_request) do
        xml_path = Rails.root.join("spec", "fixtures", "files", "project_asset_get_request.xml")
        xml = File.read(xml_path)
        Nokogiri::XML.parse(xml)
      end

      before do
        stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
          body: mediaflux_asset_get_request.to_xml
        ).to_return(status: 200, body: mediaflux_asset_get_response.to_xml)

        sign_in sponsor_user
      end

      context "when the Mediaflux assets have one or multiple files" do
        let(:mediaflux_asset_get_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_get_response.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_query_request) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_query_request.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_query_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_query_response.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_iterate_request) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_iterate_request.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_iterate_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "iterator_response_get_values.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_destroy_request) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_destroy_request.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_destroy_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_destroy_response.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end

        before do
          stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
            body: mediaflux_asset_collection_query_request.to_xml,
          ).to_return(status: 200, body: mediaflux_asset_collection_query_response.to_xml)

          stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
            body: mediaflux_asset_collection_iterate_request.to_xml,
          ).to_return(status: 200, body: mediaflux_asset_collection_iterate_response.to_xml)

          stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
            body: mediaflux_asset_collection_destroy_request.to_xml,
          ).to_return(status: 200, body: mediaflux_asset_collection_destroy_response.to_xml)
        end

        it "enqueues a Sidekiq job for asynchronously requesting project files" do
          visit project_contents_path(project_in_mediaflux)

          expect(page).to have_content("List All Files")
          click_on "List All Files"
          expect(page).to have_content("This will generate a list of 4 files and their attributes in a downloadable CSV. Do you wish to continue?")
          expect(page).to have_content("Yes")
          sleep 1
          click_on "Yes"
          expect(page).to have_content("File list for \"#{project_in_mediaflux.title}\" is being generated in the background.")
          expect(sponsor_user.user_jobs).not_to be_empty
          user_job = sponsor_user.user_jobs.first
          expect(user_job.job_id).not_to be nil
        end
      end

      context "when the storage capacity is requested, but no quota is allocated" do
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
        let(:mediaflux_asset_get_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_asset_get_response.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_query_request) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_query_request.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_query_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_query_response.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_iterate_request) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_iterate_request.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_iterate_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "iterator_response_get_values.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_destroy_request) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_destroy_request.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_destroy_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_destroy_response.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end

        before do
          stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
            body: mediaflux_asset_collection_query_request.to_xml,
          ).to_return(status: 200, body: mediaflux_asset_collection_query_response.to_xml)

          stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
            body: mediaflux_asset_collection_iterate_request.to_xml,
          ).to_return(status: 200, body: mediaflux_asset_collection_iterate_response.to_xml)

          stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
            body: mediaflux_asset_collection_destroy_request.to_xml,
          ).to_return(status: 200, body: mediaflux_asset_collection_destroy_response.to_xml)
        end

        it "renders the storage capacity in the show view" do
          visit project_contents_path(project_in_mediaflux)
          expect(page).to have_content "0 KB / 100 TB"
          expect(page).to be_axe_clean
            .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
            .skipping(:'color-contrast')
        end
      end

      context "when the quota is allocated" do
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
            storage_capacity_requested: "500 GB",
            storage_performance_expectations_requested: "Standard",
            project_purpose: "Research"
          }
        end
        let(:mediaflux_asset_get_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "collection_asset_get_response.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_query_request) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_query_request.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_query_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_query_response.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_iterate_request) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_iterate_request.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_iterate_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "iterator_response_get_values.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_destroy_request) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_destroy_request.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        let(:mediaflux_asset_collection_destroy_response) do
          xml_path = Rails.root.join("spec", "fixtures", "files", "project_with_files_asset_destroy_response.xml")
          xml = File.read(xml_path)
          Nokogiri::XML.parse(xml)
        end
        before do
          stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
            body: mediaflux_asset_collection_query_request.to_xml,
          ).to_return(status: 200, body: mediaflux_asset_collection_query_response.to_xml)

          stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
            body: mediaflux_asset_collection_iterate_request.to_xml,
          ).to_return(status: 200, body: mediaflux_asset_collection_iterate_response.to_xml)

          stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
            body: mediaflux_asset_collection_destroy_request.to_xml,
          ).to_return(status: 200, body: mediaflux_asset_collection_destroy_response.to_xml)
        end

        it "renders the storage capacity in the show view" do
          visit project_contents_path(project_in_mediaflux)
          expect(page).to have_content "6 KB / 300 GB" #should be 300 GB which is the quota, instead of 500GB which is the requested capacity
          expect(page).to be_axe_clean
            .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
            .skipping(:'color-contrast')
        end
      end
    end
  end
end
