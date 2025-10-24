# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Details Page", type: :system, connect_to_mediaflux: true, js: true do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "mjc12", mediaflux_session: SystemUser.mediaflux_session) }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "puladmin", mediaflux_session: SystemUser.mediaflux_session) }
  let(:data_manager) { FactoryBot.create(:user, uid: "kl37", mediaflux_session: SystemUser.mediaflux_session) }
  let(:read_only) { FactoryBot.create :user }
  let(:read_write) { FactoryBot.create :user }

  let(:metadata_model) do
    hash = {
      data_sponsor: sponsor_user.uid,
      data_manager: data_manager.uid,
      project_directory: "rspec-#{Time.now.utc.iso8601.tr(':', '-')}-#{rand(1..100_000)}",
      title: "project 123",
      departments: ["RDSS"],
      description: "hello world",
      data_user_read_only: [read_only.uid],
      data_user_read_write: [read_write.uid],
      status: ::Project::APPROVED_STATUS,
      storage_capacity: { "size" => { "requested" => 500 }, "unit" => { "requested" => "GB" } },
      storage_performance_expectations: { "requested" => "standard" },
      created_on: Time.current.in_time_zone("America/New_York").iso8601,
      created_by: FactoryBot.create(:user).uid,
      project_id: "10.123/456"
    }
    ProjectMetadata.new_from_hash(hash)
  end

  context "Details page" do
    let(:project_in_mediaflux) do
      request = FactoryBot.create :request_project, data_manager: sponsor_user.uid, storage_size: 500, storage_unit: "GB"
      request.approve(sponsor_and_data_manager_user)
    end
    context "Navigation Buttons" do
      context "Approved projects" do
        context "Sponsor user" do
          it "Shows the correct nav buttons" do
            sign_in sponsor_user
            project_in_mediaflux.metadata_model.status = Project::APPROVED_STATUS
            project_in_mediaflux.save!
            visit "/projects/#{project_in_mediaflux.id}/details"

            expect(page).to have_content(project_in_mediaflux.title)
            expect(page).to have_content(project_in_mediaflux.project_directory)

            expect(page).to have_css ".approved"
            # Per ticket #1114 sponsor users no longer have edit access
            expect(page).not_to have_selector(:link_or_button, "Edit") # button next to role and description heading
            expect(page).to have_selector(:link_or_button, "Content Preview")
            expect(page).to have_selector(:link_or_button, "Dashboard")
            click_on("Dashboard")
            expect(page).to have_content("Welcome, #{sponsor_user.given_name}!")
            find(:xpath, "//a[text()='#{project_in_mediaflux.title}']").click
          end
        end
        context "SysAdmin" do
          it "Shows the correct nav buttons" do
            sign_in sysadmin_user
            project_in_mediaflux.metadata_model.status = Project::APPROVED_STATUS
            project_in_mediaflux.save!
            visit "/projects/#{project_in_mediaflux.id}/details"

            # expect(page).to have_selector(:link_or_button, "Edit") # button next to project settings
            expect(page).not_to have_selector(:link_or_button, "Withdraw Project Request")
            # The project has already been approved
            expect(page).not_to have_selector(:link_or_button, "Approve Project")
          end
        end
      end
    end

    context "Approved projects" do
      it "Shows the approved values" do
        sign_in sponsor_user
        project_in_mediaflux.metadata_model.status = Project::APPROVED_STATUS
        project_in_mediaflux.metadata_model.storage_capacity["size"]["approved"] = 1
        project_in_mediaflux.metadata_model.storage_capacity["unit"]["approved"] = "TB"
        project_in_mediaflux.metadata_model.storage_performance_expectations["approved"] = "slow"
        project_in_mediaflux.save!
        visit "/projects/#{project_in_mediaflux.id}/details"

        expect(page).to have_content(project_in_mediaflux.title)
        expect(page).to have_content("Storage Capacity\nRequested\n500.0 GB\nApproved\n1 TB")
        # expect(page).to have_content("Storage Performance Expectations\nRequested\nstandard\nApproved\nslow")
        expect(page).to have_content("RDSS")
      end
    end

    context "Provenance Events" do
      let(:project) { FactoryBot.create(:project, data_sponsor: sponsor_user.uid) }
      let(:submission_event) { FactoryBot.create(:submission_event, project: project) }
      it "shows provenance events" do
        submission_event
        sign_in sponsor_user
        visit "/projects/#{project.id}/details"
        expect(page).to have_content "#{submission_event.event_details}, #{submission_event.created_at.to_time.in_time_zone('America/New_York').iso8601}"
      end
      it "shows the project status under the provenance section" do
        submission_event
        sign_in sponsor_user
        visit "/projects/#{project.id}"
        expect(page).to have_css ".approved"
      end
    end

    context "Project Contents", connect_to_mediaflux: true, integration: true do
      let(:request) { FactoryBot.create :request_project, data_sponsor: sponsor_user.uid }
      let(:project) { create_project_in_mediaflux(current_user: sponsor_user, request:) }
      let(:file_list) { project.file_list(session_id: sponsor_user.mediaflux_session, size: 100)[:files].sort_by!(&:path) }
      let(:first_file) { file_list.find { |asset| asset.collection == false } }
      let(:second_file) { file_list.select { |asset| asset.collection == false }.second }
      let(:last_file) { file_list.reverse.find { |asset| asset.collection == false } }

      before do
        # Create a project in mediaflux and generate assets for the collection
        TestAssetGenerator.new(user: sponsor_user, project_id: project.id, levels: 2, directory_per_level: 2, file_count_per_directory: 4).generate
      end

      after do
        Mediaflux::AssetDestroyRequest.new(session_token: sponsor_user.mediaflux_session, collection: project.mediaflux_id, members: true).resolve
      end

      it "renders the storage quota usage component" do
        sign_in sponsor_user

        visit "/projects/#{project.id}/details"
        expect(page).to have_selector(:link_or_button, "Content Preview")
        click_on("Content Preview")
      end

      it "Contents page has collection summary data",
      :integration do
        # sign in and be able to view the file count for the collection
        sign_in sponsor_user
        visit "/projects/#{project.id}/details"
        expect(page).to have_selector(:link_or_button, "Content Preview")
        click_on("Content Preview")
        expect(page).to have_content("8 out of 16 shown")
        # expect(find(:css, "#file_count").text).to eq "16"

        # Be able to return to the dashboard
        expect(page).to have_selector(:link_or_button, "Dashboard")
        click_on("Dashboard")
        expect(page).to have_content("Welcome, #{sponsor_user.given_name}!")
        find(:xpath, "//a[text()='#{project.title}']").click
        expect(page).to have_content(project.title)
      end

      it "displays the caveat message" do
        # sign in and be able to view the file count for the collection
        sign_in sponsor_user
        visit "/projects/#{project.id}/details"
        expect(page).to have_selector(:link_or_button, "Content Preview")
        click_on("Content Preview")

        # Caveat message is displayed
        expect(page).to have_content("Showing the first 100 files due to preview limit.")
      end

      it "displays the file list",
      :integration do
        # sign in and be able to view the file count for the collection
        sign_in sponsor_user
        visit "/projects/#{project.id}/details"
        expect(page).to have_selector(:link_or_button, "Content Preview")
        click_on("Content Preview")

        # Files are displayed
        expect(page).to have_content(first_file.name)
        expect(page).to have_content(second_file.name)
        expect(page).not_to have_content(last_file.name)

        # files are paginated
        find("a.paginate_button", text: 2).click
        expect(page).to have_content(last_file.name)
      end

      context "when downloads do not exist" do
        it "does not include a link to the latest download in the download modal" do
          sign_in sponsor_user
          visit "/projects/#{project.id}"
          click_on("Download Complete List")
          expect(page).not_to have_content("Download latest")
        end
      end

      context "when downloads exist" do
        before do
          FileInventoryJob.new(user_id: sponsor_user.id, project_id: project.id, mediaflux_session: sponsor_user.mediaflux_session).perform_now
        end
        it "includes a link to the latest download in the download modal" do
          sign_in sponsor_user
          visit "/projects/#{project.id}"
          click_on("Download Complete List")
          expect(page).to have_content("Download latest report - generated less than a minute ago")
        end
      end
    end

    context "system administrator" do
      let(:project_in_mediaflux) { FactoryBot.create(:project, mediaflux_id: 1234, status: Project::APPROVED_STATUS, metadata_model: metadata_model) }
      let(:project_not_in_mediaflux) { FactoryBot.create(:project) }
      it "shows the sysadmin buttons for an approved project" do
        sign_in sysadmin_user
        visit "/projects/#{project_in_mediaflux.id}/details"

        expect(page).to have_content project_in_mediaflux.project_directory
        expect(page).to have_content "project 123"
        expect(page).to have_content "1234"
        expect(page).not_to have_content "This project has not been saved to Mediaflux"
      end

      it "does not show the mediaflux id to the sponsor" do
        sign_in sponsor_user
        visit "/projects/#{project_in_mediaflux.id}/details"
        expect(page).to have_content "project 123"
        expect(page).not_to have_content "1234"
        expect(page).not_to have_content "This project has not been saved to Mediaflux"
        expect(page).not_to have_selector(:link_or_button, "Approve Project")
        expect(page).not_to have_selector(:link_or_button, "Deny Project")
      end
    end
  end
end
