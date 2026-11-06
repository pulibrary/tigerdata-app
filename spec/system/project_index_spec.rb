# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Index Page", type: :system do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit projects_path
      expect(page).to have_text "You need to sign in or sign up before continuing."
    end
  end

  context "authenticated user" do
    let(:researcher_user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
    let(:project_not_in_mediaflux) { FactoryBot.create(:project, data_sponsor: "pul123", data_manager: "pul123") }

    before do
      sign_in researcher_user
      project_not_in_mediaflux
    end

    it "shows access denied" do
      visit "/projects"
      expect(page).to have_text("Access Denied")
    end
  end

  context "system admin user" do
    let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
    let(:project_not_in_mediaflux) { FactoryBot.create(:project, data_sponsor: "pul123", data_manager: "pul123", title: "no mediaflux pop") }
    let(:metadata_model_not_in_mediaflux) { ProjectMetadata.new(project_not_in_mediaflux) }

    let(:request1) { FactoryBot.create(:request_project, project_title: "soda pop") }
    let(:request2) { FactoryBot.create(:request_project, project_title: "orange pop") }
    let(:request3) { FactoryBot.create(:request_project, project_title: "grape soda") }

    let!(:project1) { create_project_in_mediaflux(request: request1, current_user: sysadmin_user) }
    let(:metadata_model1) { ProjectMetadata.new(project1) }
    let!(:project2) { create_project_in_mediaflux(request: request2, current_user: sysadmin_user) }
    let(:metadata_model2) { ProjectMetadata.new(project2) }
    let!(:project3) { create_project_in_mediaflux(request: request3, current_user: sysadmin_user) }
    let(:metadata_model3) { ProjectMetadata.new(project3) }

    after do
      Mediaflux::AssetDestroyRequest.new(session_token: sysadmin_user.mediaflux_session, collection: project1.mediaflux_id, members: true).resolve
      Mediaflux::AssetDestroyRequest.new(session_token: sysadmin_user.mediaflux_session, collection: project2.mediaflux_id, members: true).resolve
      Mediaflux::AssetDestroyRequest.new(session_token: sysadmin_user.mediaflux_session, collection: project3.mediaflux_id, members: true).resolve
    end

    before do
      sign_in sysadmin_user
      project_not_in_mediaflux
    end

    it "shows the existing projects" do
      visit "/projects"
      expect(page).not_to have_text("Access Denied")
      expect(page).not_to have_link(metadata_model_not_in_mediaflux.title)
      expect(page).to have_link(metadata_model1.title)
      expect(page).to have_text(metadata_model1.project_directory)
      expect(page).to have_text(project1.mediaflux_id)
      expect(page).to have_link(metadata_model2.title)
      expect(page).to have_text(metadata_model2.project_directory)
      expect(page).to have_text(project2.mediaflux_id)
      expect(page).to have_link(metadata_model3.title)
      expect(page).to have_text(metadata_model3.project_directory)
      expect(page).to have_text(project3.mediaflux_id)
      fill_in "title_query", with: "*pop*"
      click_on "Search"
      expect(page).to have_text("Successful search in Mediaflux for *pop*")
      expect(page).not_to have_link(metadata_model_not_in_mediaflux.title)
      expect(page).to have_link(metadata_model1.title)
      expect(page).to have_link(metadata_model2.title)
      expect(page).not_to have_link(metadata_model3.title)
      fill_in "title_query", with: "soda*"
      click_on "Search"
      sleep(0.2)
      expect(page).to have_text("Successful search in Mediaflux for soda*")
      expect(page).not_to have_link(metadata_model_not_in_mediaflux.title)
      expect(page).to have_link(metadata_model1.title)
      expect(page).not_to have_link(metadata_model2.title)
      expect(page).not_to have_link(metadata_model3.title)
    end
  end
end
