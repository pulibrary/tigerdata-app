# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Page", connect_to_mediaflux: true, type: :system  do
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "puladmin", mediaflux_session: SystemUser.mediaflux_session) }
  let(:developer) { FactoryBot.create(:developer, uid: "root", mediaflux_session: SystemUser.mediaflux_session) }
  let!(:data_manager) { FactoryBot.create(:data_manager, uid: "mjc12", mediaflux_session: SystemUser.mediaflux_session) }
  let(:read_only) { FactoryBot.create :user, uid: "cac9" }
  let(:read_write) { FactoryBot.create :user, uid: "pp9425" }
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
    it "shows access denied for Projects not in Mediaflux" do
      sign_in data_manager
      visit "/projects/#{project_not_in_mediaflux.id}/details"
      expect(page).to have_content "Access Denied"
    end
  end

  context "GET /projects/:id" do
    context "when authenticated with assets" do
      let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
      let(:completion_time) { Time.current.in_time_zone("America/New_York").iso8601 }
      let!(:approved_project) do
        request = FactoryBot.create(:request_project)
        request.approve(sponsor_and_data_manager_user)
      end
      let(:test_strategy) { Flipflop::FeatureSet.current.test! }

      before do
        sign_in sponsor_and_data_manager_user
        # Create file(s) for the project in mediaflux using test asset create request
        Mediaflux::TestAssetCreateRequest.new(session_token: sponsor_and_data_manager_user.mediaflux_session, parent_id: approved_project.mediaflux_id, pattern: "SampleFile.txt").resolve
        Mediaflux::TestAssetCreateRequest.new(session_token: sponsor_and_data_manager_user.mediaflux_session, parent_id: approved_project.mediaflux_id, count: 3, pattern: "RandomFile.txt").resolve

        @current_state = test_strategy.enabled?(:new_file_details)
        test_strategy.switch!(:new_file_details, false)
      end

      after do
        test_strategy.switch!(:new_file_details, @current_state)
      end

      context "The new_file_details feature is turned on" do
        before do
          test_strategy.switch!(:new_file_details, true)
        end
        let(:project) { test_project_from_path("/princeton/tigerdata/RDSS/Query/BProject") }
        let(:empty_project_folder) { test_project_from_path("/princeton/tigerdata/RDSS/Query/AProject") }
        let(:large_project) { test_project_from_path("/princeton/tigerdata/RDSS/Query/CProject") }

        it "displays the new file feature" do
          visit project_path(project)

          within(".breadcrumb-container") do
            expect(page).to have_css("svg[class*='home-icon']")
            expect(page).to have_css("li", text: "BProject")
            page.find(".sizer").click
            expect(page).to have_css ".check"
          end

          expect(page).to have_content("A0")

          page.find(".browser-collection", text: "parent_1").click
          sleep(0.1)

          within(".breadcrumb-container") do
            expect(page).to have_css("li", text: "BProject")
            expect(page).to have_css("li", text: "parent_1")
          end

          page.find(".browser-collection", text: "child_1").click
          within(".breadcrumb-container") do
            expect(page).to have_css("li", text: "BProject")
            expect(page).to have_css("li", text: "parent_1")
            expect(page).to have_css("li", text: "child_1")
          end

          page.find("li", text: "parent_1").click # click on parent_1 in the breadcrumb to go back up to that level
          within(".files-viewer") do
            expect(page).to have_content("child_1")
          end
        end

        it "displays an empty folder indicator" do
          visit project_path(empty_project_folder)
          expect(page).to have_css("li", text: "AProject")
          page.find(".browser-collection", text: "empty_directory").click
          sleep(0.1)
          expect(page).to have_content("This folder is empty")
        end

        it "displays the file details component" do
          visit project_path(project)
          dir_listing = project.directory_listing(session_id: SystemUser.mediaflux_session)
          project_files = dir_listing[:files]
          last_modified_date = project_files.first.last_modified.strftime("%m/%d/%Y")
          within(".project-file") do
            expect(page).to have_css("header", text: "File Name")
            expect(page).to have_css("p", text: "A0")
            expect(page).to have_css("header", text: "File Size")

            expect(page).to have_css("p", text: "10 Bytes")
            expect(page).to have_css("header", text: "File Type")
            expect(page).to have_css("header", text: "Location")
            have_css("p", text: "/tigerdata/RDSS/Query/CProject/A0")
            expect(page).to have_css("header", text: "Modified Date")
            have_css("p", text: last_modified_date)
            expect(page).to have_css(".sizer") # check that the copy path button is present
            expect(page).not_to have_css(".tooltiptext", text: "TigerData uses base-10 units for bytes")
            find(".info-container .tooltip-container").click
            expect(page).to have_css(".tooltiptext", text: "TigerData uses base-10 units for bytes")
          end
          page.all("tr")[6].click
          within(".project-file") do
            expect(page).to have_css("header", text: "Folder Name")
            expect(page).to have_css("p", text: "parent_1")
            expect(page).to have_css("header", text: "Folder Size")
            expect(page).to have_css("p", text: "950 Bytes")
            expect(page).to have_css("header", text: "Item Count")
            expect(page).to have_css("p", text: "97")
            expect(page).to have_css("header", text: "Location")
            have_css("p", text: "/tigerdata/RDSS/Query/CProject/parent_1")
            expect(page).to have_css("header", text: "Modified Date")
            have_css("p", text: last_modified_date)
            expect(page).to have_css(".sizer") # check that the copy path button is present
            expect(page).not_to have_css(".tooltiptext", text: "This number reflects all items")
            find(".info-container .tooltip-container").click
            expect(page).to have_css(".tooltiptext", text: "This number reflects all items")
            expect(page).to have_content("This number reflects all items")
          end
        end

        it "displays an the file warning indicator when appropriate" do
          visit project_path(large_project)
          dir_listing = large_project.directory_listing(session_id: SystemUser.mediaflux_session)
          project_files = dir_listing[:files]
          last_modified_date = project_files.first.last_modified.strftime("%m/%d/%Y")

          expect(page).to have_selector(".project-file-details header", text: "File Name")
          expect(page).to have_selector("[data-attribute-name='fileName']", text: "A0")
          expect(page).to have_selector(".project-file-details header", text: "File Size")
          expect(page).to have_selector("[data-attribute-name='fileSize']", text: "10")
          expect(page).to have_selector(".project-file-details header", text: "Location")
          expect(page).to have_selector("[data-attribute-name='location']", text: "/tigerdata/RDSS/Query/CProject/A0")
          expect(page).to have_selector(".project-file-details header", text: "Modified Date")
          expect(page).to have_selector("[data-attribute-name='modifiedDate']", text: last_modified_date)
          expect(page).to have_selector(".project-file-details header", text: "Created Date")
          expect(page).to have_selector("[data-attribute-name='createdDate']", text: last_modified_date)
          expect(page).to have_selector(".project-file-details header", text: "Created By")
          expect(page).to have_selector("[data-attribute-name='createdBy']", text: "System Generated")

          expect(page).to have_css("li", text: "CProject")
          # should not show the warning because we are under the limit
          expect(page).not_to have_content("The preview screen can display up to #{Rails.configuration.project_file_display_limit} items per folder")
          page.find(".browser-collection", text: "n_01000").click
          sleep(0.1)
          within(".files-viewer") do
            expect(page).to have_content("A99")
          end

          expect(page).to have_selector(".project-file-details header", text: "File Name")
          expect(page).to have_selector("[data-attribute-name='fileName']", text: "A0")
          expect(page).to have_selector(".project-file-details header", text: "File Size")
          expect(page).to have_selector("[data-attribute-name='fileSize']", text: "10")
          expect(page).to have_selector(".project-file-details header", text: "Location")
          expect(page).to have_selector("[data-attribute-name='location']", text: "/tigerdata/RDSS/Query/CProject/n_01000/A0")
          expect(page).to have_selector(".project-file-details header", text: "Modified Date")
          expect(page).to have_selector("[data-attribute-name='modifiedDate']", text: last_modified_date)
          expect(page).to have_selector(".project-file-details header", text: "Created Date")
          expect(page).to have_selector("[data-attribute-name='createdDate']", text: last_modified_date)

          # should show the warning because we are above the limit
          expect(page).to have_content("The preview screen can display up to #{Rails.configuration.project_file_display_limit} items per folder")
          page.find("li", text: "CProject").click

          # TODO: This shows the mediaflux issue in that they are indicating complete is false when the iterator show exactly the number of items as the size limit.
          #       We should not be showing the warning in this case because we are not actually over the limit.
          within(".files-viewer") do
            expect(page).to have_content("n_00100")
          end
          page.find(".browser-collection", text: "n_00100").click
          sleep(0.1)
          expect(page).to have_content("E19")
          # #should not show the warning because we are at the limit
          # expect(page).not_to have_content("The preview screen can display up to #{Rails.configuration.project_file_display_limit} items per folder")
        end
      end

      it "enqueues a Sidekiq job for asynchronously requesting project files",
        :integration do
        visit project_path(approved_project)

        expect(page).not_to have_content("show level by level browser here")

        expect(page).to have_content("Download Complete List")
        click_on "Download Complete List"
        expect(page).to have_content("This will generate a list of 4 files and their attributes in a downloadable CSV. Do you wish to continue?")
        expect(page).to have_content("Yes")
        sleep 1
        click_on "Yes"
        expect(page).to have_content("File list for \"#{approved_project.title}\" is being generated in the background.")
        expect(sponsor_and_data_manager_user.inventory_requests.count).to eq(1)
        expect(sponsor_and_data_manager_user.inventory_requests.first.job_id).not_to be nil
        expect(sponsor_and_data_manager_user.inventory_requests.first.state).to eq FileInventoryRequest::PENDING
        expect(sponsor_and_data_manager_user.inventory_requests.first.type).to eq "FileInventoryRequest"
      end

      context "when the new_file_details feature is turned on" do
        let(:last_modified) { Time.current.in_time_zone("America/New_York").iso8601 }
        before do
          test_strategy.switch!(:new_file_details, true)
        end
        it "does not display the preview alert when the number of files does not exceed the project file display limit" do
          visit project_path(approved_project)

          expect(page).not_to have_content("The preview screen can display up to #{Rails.configuration.project_file_display_limit} items per folder")
        end
      end

      it "renders the storage capacity in the show view", :integration do
        visit project_path(approved_project)

        expect(page).to have_content "Storage (500 GB)"
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

          # TODO: Why are we not getting a storageCapacity anymore?
          #       I suspect it is because we were updating the project directly with this information
          #       but we don't update this information anymore when we create a project through a request.
          #
          # expect(xml).to include("<storageCapacity approved=\"true\" inherited=\"false\" discoverable=\"false\" trackingLevel=\"InternalUseOnly\"/>")

          expect(xml).to include("<storagePerformance inherited=\"false\" discoverable=\"false\" trackingLevel=\"InternalUseOnly\" approved=\"true\">")
          expect(xml).to include("<requestedValue>Standard</requestedValue>")
          expect(xml).to include("</storagePerformance>")
          expect(xml).to include("<projectPurpose inherited=\"true\" discoverable=\"true\" trackingLevel=\"InternalUseOnly\">Research</projectPurpose>")
        end
      end
    end
  end
end
