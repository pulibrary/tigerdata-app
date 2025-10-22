# frozen_string_literal: true

require "rails_helper"

describe "Current Users page", type: :system, connect_to_mediaflux: false, js: true do
  let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul456", mediaflux_session: SystemUser.mediaflux_session) }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "puladmin", mediaflux_session: SystemUser.mediaflux_session) }
  let(:developer) { FactoryBot.create(:developer, uid: "root", mediaflux_session: SystemUser.mediaflux_session) }
  let!(:data_manager) { FactoryBot.create(:data_manager, uid: "pul987", mediaflux_session: SystemUser.mediaflux_session) }
  let(:user_without_provider) { FactoryBot.create(:data_manager, provider: "", mediaflux_session: SystemUser.mediaflux_session) }

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
      expect(page).to have_content "You do not have access to this page (#{current_user.uid})"
    end
  end

  context "system administrator" do
    it "shows the Current Users page" do
      sign_in sysadmin_user
      visit "/users"
      expect(page).to have_content "Current Users"
    end
  end

  context "developer" do
    it "shows the Current Users page" do
      sign_in developer
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
    it "shows the error message when visiting the users page" do
      sign_in sponsor_user
      visit "/users"
      expect(page).to have_content "You do not have access to this page (#{sponsor_user.uid})"
    end

    it "shows the error message when visiting the user show page" do
      sign_in sponsor_user
      visit "/users/#{data_manager.id}"
      expect(page).to have_content "You do not have access to this page (#{sponsor_user.uid})"
    end
  end

  context "data manager" do
    it "shows the error message" do
      sign_in data_manager
      visit "/users"
      expect(page).to have_content "You do not have access to this page (#{data_manager.uid})"
    end
  end

  context "edit user" do
    let(:new_given_name) { FFaker::Name.name }
    it "shows the user information" do
      sign_in sysadmin_user
      visit "/users/#{data_manager.id}"
      expect(page).to have_content "NetID: #{data_manager.uid}"
      expect(page).to have_content "Provider: cas"
      expect(page).to have_button "Edit"
    end

    it "warns if the authentication provider is not set" do
      sign_in sysadmin_user
      visit "/users/#{user_without_provider.id}"
      expect(page).to have_content "Provider: not set"
    end

    it "allows user to edit information" do
      sign_in sysadmin_user
      visit "/users/#{data_manager.id}/edit"
      fill_in :user_given_name, with: new_given_name
      click_on "Save"
      expect(page).to have_content("Give name: #{new_given_name}")
      expect(User.find(data_manager.id).given_name).to eq new_given_name
    end
  end

  # Notice that this is a system test because it requires an active Mediaflux session
  describe "user#current_user_mediaflux_roles" do
    let(:user_without_session) { FactoryBot.create(:user, uid: "nosession123") }

    it "detects mediaflux roles" do
      sign_in sysadmin_user
      roles = User.mediaflux_roles(user: sysadmin_user)
      expect(roles.include?("system-administrator")).to be true
    end

    it "raises an error if the user does not have a Mediaflux session" do
      expect do
        User.mediaflux_roles(user: user_without_session)
      end.to raise_error(StandardError)
    end
  end

  describe "user#update_user_roles" do
    before do
      sysadmin_user.developer = false
      sysadmin_user.sysadmin = false
      sysadmin_user.save!
    end

    it "mark as developer an admin and a developer user" do
      expect(sysadmin_user.sysadmin).to be false
      expect(sysadmin_user.developer).to be false
      sign_in sysadmin_user
      User.update_user_roles(user: sysadmin_user)
      expect(sysadmin_user.sysadmin).to be true
      expect(sysadmin_user.developer).to be true
    end
  end
end
