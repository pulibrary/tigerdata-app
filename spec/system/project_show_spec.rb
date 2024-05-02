  # frozen_string_literal: true

  require "rails_helper"

  RSpec.describe "Project Page", type: :system, stub_mediaflux: true, js: true do
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

    let(:project_in_mediaflux) { FactoryBot.create(:project, mediaflux_id: 8888, metadata: metadata) }
    let(:project_not_in_mediaflux) { FactoryBot.create(:project, metadata: metadata) }
    context "Show page" do
      context "Navigation Buttons" do
        it "Shows the correct nav buttons for an approved project" do
          sign_in sponsor_user
          project_in_mediaflux.metadata_json["status"] = Project::APPROVED_STATUS
          project_in_mediaflux.save!
          visit "/projects/#{project_in_mediaflux.id}"

          expect(page).to have_content(project_in_mediaflux.title)
          expect(page).not_to have_content(pending_text)
          expect(page).to have_link("Edit") #button next to role and description heading
          click_on("Return to Dashboard")
          expect(page).to have_content("Welcome, #{sponsor_user.given_name}!")
          click_on(project_in_mediaflux.title)
          expect(page).to have_link("Withdraw Project Request")
        end

        it "Shows the correct nav buttons for a pending project" do
          sign_in sponsor_user
          visit "/projects/#{project_not_in_mediaflux.id}"
          expect(page).to have_content(project_not_in_mediaflux.title)
          expect(page).to have_content(pending_text)
          expect(page).not_to have_link("Edit")
          click_on("Return to Dashboard")
          expect(page).to have_content("Welcome, #{sponsor_user.given_name}!")
          click_on(project_not_in_mediaflux.title)
          expect(page).to have_link("Withdraw Project Request")
        end
      end

      context "Provenance Events" do
        let(:project) { FactoryBot.create(:project, project_id: "jh34", data_sponsor: sponsor_user.uid) }
        let(:submission_event) { FactoryBot.create(:submission_event, project: project) }
        it "shows provenance events" do
          submission_event
          sign_in sponsor_user
          visit "/projects/#{project.id}"
          expect(page).to have_content "#{submission_event.event_details}, #{submission_event.created_at.to_time.in_time_zone('America/New_York').iso8601}"
        end
        it "shows the project status under the provenance section" do
          submission_event
          sign_in sponsor_user
          visit "/projects/#{project.id}"
          expect(page).to have_content "Status\n#{::Project::PENDING_STATUS}"
        end
      end

      context "Project Contents", connect_to_mediaflux: true do
        let(:project) { FactoryBot.create(:project, project_id: "jh34", data_sponsor: sponsor_user.uid, directory: FFaker::Food.ingredient.underscore) }
        let(:file_list) { project.file_list(session_id: sponsor_user.mediaflux_session, size: 100)[:files].sort_by!(&:path) }
        let(:first_file) { file_list.select { |asset| asset.collection == false }.first }
        let(:second_file) { file_list.select { |asset| asset.collection == false }.second }
        let(:last_file) { file_list.select { |asset| asset.collection == false }.last }

        before do
          session_id = sponsor_user.mediaflux_session

          # Create a project in mediaflux, attach an accumulator, and generate assests for the collection
          project.mediaflux_id = ProjectMediaflux.create!(project:, session_id: )
          project.save!
          accum_req = Mediaflux::Http::CreateCollectionAccumulatorRequest.new(session_token: session_id, collection: project.mediaflux_id, name:"file count", type:"collection.asset.count")
          accum_req.resolve
          TestAssetGenerator.new(user: sponsor_user, project_id: project.id, levels: 2, directory_per_level: 2, file_count_per_directory: 4).generate
        end

        after do
          Mediaflux::Http::AssetDestroyRequest.new(session_token: sponsor_user.mediaflux_session, collection: project.mediaflux_id, members: true).resolve
        end

        it "Contents page has collection summary data" do
          # sign in and be able to view the file count for the collection
          sign_in sponsor_user
          visit "/projects/#{project.id}"
          expect(page).to have_selector(:link_or_button, "Review Contents")
          click_on("Review Contents")
          expect(page).to have_content("Project Contents")
          expect(page).to have_content("File Count")
          expect(find(:css, "#file_count").text).to eq "16"

          # Be able to return to the dashboard
          expect(page).to have_selector(:link_or_button, "Return to Dashboard")
          click_on("Return to Dashboard")
          expect(page).to have_content("Welcome, #{sponsor_user.given_name}!")
          click_on(project.title)
          expect(page).to have_content("Project Details: #{project.title}")
        end

        it "displays the file list" do
          # sign in and be able to view the file count for the collection
          sign_in sponsor_user
          visit "/projects/#{project.id}"
          expect(page).to have_selector(:link_or_button, "Review Contents")
          click_on("Review Contents")

          # Files are displayed
          expect(page).to have_content(first_file.name)
          expect(page).to have_content(second_file.name)
          expect(page).not_to have_content(last_file.name)

          # More files are displayed
          click_on("Show More")
          expect(page).to have_content(last_file.name)
        end
      end

      context "system administrator" do
        let(:project_in_mediaflux) { FactoryBot.create(:project, mediaflux_id: 1234, status: Project::APPROVED_STATUS, metadata: metadata) }
        let(:project_not_in_mediaflux) { FactoryBot.create(:project) }
        it "shows the sysadmin buttons for an approved project" do
          sign_in sysadmin_user
          visit  "/projects/#{project_in_mediaflux.id}"
          expect(page).to have_content "project 123"
          expect(page).not_to have_content "This project has not been saved to Mediaflux"
          expect(page).not_to have_content pending_text
          expect(page).to have_selector(:link_or_button, "Return to Dashboard")
        end
        it "shows the sysadmin buttons for a pending project" do
          sign_in sysadmin_user
          visit  "/projects/#{project_not_in_mediaflux.id}"
          expect(page).to have_content "#{project_not_in_mediaflux.metadata[:title]} (#{::Project::PENDING_STATUS})"
          expect(page).to have_content "This project has not been saved to Mediaflux"
          expect(page).to have_content pending_text
          expect(page).to have_selector(:link_or_button, "Approve Project")
          expect(page).to have_selector(:link_or_button, "Deny Project")
          expect(page).to have_selector(:link_or_button, "Return to Dashboard")
        end
      end
    end
  end
