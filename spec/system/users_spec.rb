# frozen_string_literal: true

require "rails_helper"

describe "Current Users page", type: :system, connect_to_mediaflux: false, js: true do
  let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul456", mediaflux_session: SystemUser.mediaflux_session) }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "puladmin", mediaflux_session: SystemUser.mediaflux_session) }
  let(:superuser) { FactoryBot.create(:superuser, uid: "root", mediaflux_session: SystemUser.mediaflux_session) }
  let!(:data_manager) { FactoryBot.create(:data_manager, uid: "pul987", mediaflux_session: SystemUser.mediaflux_session) }

  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/users"
      expect(page).to have_content "Log in"
    end
  end

  context "authenticated user" do
    it "shows the error message" do
      sign_in current_user
      visit "/users"
      expect(page).to have_content "You do not have access to this page."
    end
  end

  context "system administrator" do
    it "shows the Current Users page" do
      sign_in sysadmin_user
      visit "/users"
      expect(page).to have_content "Current Users"
    end
  end

  context "superuser" do
    it "shows the Current Users page" do
      sign_in superuser
      visit "/users"
      expect(page).to have_content "Current Users"
    end
  end

  context "trainer" do
    it "shows the the Current Users page" do
      sign_in current_user
      current_user.trainer = true
      current_user.save!
      visit "/users"
      expect(page).to have_content "Current Users"
    end
  end

  context "data sponsor" do
    it "shows the error message" do
      sign_in sponsor_user
      visit "/users"
      expect(page).to have_content "You do not have access to this page."
    end
  end

  context "data manager" do
    it "shows the error message" do
      sign_in data_manager
      visit "/users"
      expect(page).to have_content "You do not have access to this page."
    end
  end
end
