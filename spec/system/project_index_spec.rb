# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Index Page", type: :system do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit projects_path
      expect(page).to have_content "You need to sign in or sign up before continuing."
    end
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
    let(:project_not_in_mediaflux) { FactoryBot.create(:project, data_sponsor: "pul123", data_manager: "pul123") }

    before do
      sign_in current_user
      project_not_in_mediaflux
    end

    it "shows the existing projects" do
      visit "/projects"
      expect(page).to have_content("Access Denied")
      expect(page).to have_content(project_not_in_mediaflux.title)
    end
  end

  context "system admin user" do
    let(:current_user) { FactoryBot.create(:sysadmin, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
    let(:project_not_in_mediaflux) { FactoryBot.create(:project, data_sponsor: "pul123", data_manager: "pul123", title: "no mediaflux pop") }

    let(:request1) { FactoryBot.create(:request_project, project_title: "soda pop") }
    let(:request2) { FactoryBot.create(:request_project, project_title: "orange pop") }
    let(:request3) { FactoryBot.create(:request_project, project_title: "grape soda") }

    let!(:project1) { create_project_in_mediaflux(request: request1, current_user: current_user) }
    let!(:project2) { create_project_in_mediaflux(request: request2, current_user: current_user) }
    let!(:project3) { create_project_in_mediaflux(request: request3, current_user: current_user) }

    after do
      Mediaflux::AssetDestroyRequest.new(session_token: current_user.mediaflux_session, collection: project1.mediaflux_id, members: true).resolve
      Mediaflux::AssetDestroyRequest.new(session_token: current_user.mediaflux_session, collection: project2.mediaflux_id, members: true).resolve
      Mediaflux::AssetDestroyRequest.new(session_token: current_user.mediaflux_session, collection: project3.mediaflux_id, members: true).resolve
    end

    before do
      sign_in current_user
      project_not_in_mediaflux
    end

    it "shows the existing projects" do
      visit "/projects"
      expect(page).not_to have_content("Access Denied")
      expect(page).to have_link(project_not_in_mediaflux.title)
      expect(page).to have_link(project1.title)
      expect(page).to have_content(project1.metadata_model.project_directory)
      expect(page).to have_content(project1.mediaflux_id)
      expect(page).to have_link(project2.title)
      expect(page).to have_content(project2.metadata_model.project_directory)
      expect(page).to have_content(project2.mediaflux_id)
      expect(page).to have_link(project3.title)
      expect(page).to have_content(project3.metadata_model.project_directory)
      expect(page).to have_content(project3.mediaflux_id)
      fill_in "title_query", with: "*pop*"
      click_on "Search"
      expect(page).to have_content("Successful search in Mediaflux for *pop*")
      expect(page).not_to have_link(project_not_in_mediaflux.title)
      expect(page).to have_link(project1.title)
      expect(page).to have_link(project2.title)
      expect(page).not_to have_link(project3.title)
      fill_in "title_query", with: "soda*"
      click_on "Search"
      expect(page).to have_content("Successful search in Mediaflux for soda*")
      expect(page).not_to have_link(project_not_in_mediaflux.title)
      expect(page).to have_link(project1.title)
      expect(page).not_to have_link(project2.title)
      expect(page).not_to have_link(project3.title)
    end
  end
end
