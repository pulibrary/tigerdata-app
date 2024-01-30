# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Page", type: :system, stub_mediaflux: true do
  let(:sponsor_user) { FactoryBot.create(:user, uid: "pul123") }
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
  context "Show page" do
    it "shows the project correct navigation buttons" do
      sign_in sponsor_user
      visit "/projects/#{project_not_in_mediaflux.id}"
      expect(page).to have_content(project_not_in_mediaflux.title)
      expect(page).to have_link("Edit")
      click_on("Return to Dashboard")
      expect(page).to have_content("Welcome, #{sponsor_user.given_name}!")
      click_on(project_not_in_mediaflux.title)
      expect(page).to have_link("Withdraw Project Request")
    end
    context "Provenance Events" do
      let(:project) { FactoryBot.create(:project, metadata: metadata) }
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
      it "can take the user to the project contents page" do
        submission_event
        sign_in sponsor_user
        visit "/projects/#{project.id}"
        expect(page).to have_selector(:link_or_button, "Review Contents")
        click_on("Review Contents")
        expect(page).to have_content("Project Contents")
        # Be able to return to the dashboard
        expect(page).to have_selector(:link_or_button, "Return to Dashboard")
        click_on("Return to Dashboard")
        expect(page).to have_content("Welcome, #{sponsor_user.given_name}!")
        click_on(project.title)
        expect(page).to have_content("Project Details: #{project.title}")
      end
    end
  end
end
