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
    let(:project_not_in_mediaflux) { FactoryBot.create(:project, data_sponsor: "pul123", data_manager: "pul123") }

    before do
      sign_in current_user
      project_not_in_mediaflux
    end

    it "shows the existing projects" do
      visit "/projects"
      expect(page).not_to have_content("Access Denied")
      expect(page).to have_link(project_not_in_mediaflux.title)
    end
  end
end
