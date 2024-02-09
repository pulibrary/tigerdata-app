# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WelcomeController", stub_mediaflux: true do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "Welcome to TigerData"
      expect(page).to have_content "Log In"
      expect(page).to have_link "Accessibility", href: "https://accessibility.princeton.edu/help"
    end
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
    let(:other_user) { FactoryBot.create(:user, uid: "zz123") }
    let(:no_projects_user) { FactoryBot.create(:user, uid: "qw999") }
    before do
      FactoryBot.create(:project, metadata: { data_sponsor: current_user.uid, data_manager: other_user.uid, title: "project 111" })
      FactoryBot.create(:project, metadata: { data_sponsor: other_user.uid, data_manager: current_user.uid, title: "project 222" })
      FactoryBot.create(:project, metadata: { data_sponsor: other_user.uid, data_manager: other_user.uid, data_user_read_only: [current_user.uid], title: "project 333" })
      FactoryBot.create(:project, metadata: { data_sponsor: other_user.uid, data_manager: other_user.uid, title: "project 444" })
    end

    context "current user dashboard" do
      it "shows the 'Log Out' button" do
        sign_in current_user
        visit "/"
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        expect(page).not_to have_content "Please log in"
        expect(page).to have_content "Log Out"
      end
      it "shows the user projects regardless of the user's role" do
        sign_in current_user
        visit "/"
        expect(page).to have_content "Sponsored by Me"
        expect(page).to have_content "project 111"
        expect(page).to have_content "Managed by Me"
        expect(page).to have_content "project 222"
        expect(page).to have_content "Shared with Me"
        expect(page).to have_content "project 333"
        # The current user has no access to this project so we don't expect to see it
        expect(page).not_to have_content "project 444"
      end
    end

    context "for a user without any projects" do
      it "shows the 'Log Out' button" do
        sign_in no_projects_user
        visit "/"
        expect(page).not_to have_content "Please log in"
        expect(page).to have_content "Log Out"
      end
      it "does not show any projects" do
        sign_in no_projects_user
        visit "/"
        expect(page).not_to have_content "Sponsored by Me"
      end
    end

    context "with the superuser role" do
      let(:current_user) { FactoryBot.create(:superuser, uid: "pul123") }

      it "shows the 'New Project' button" do
        sign_in current_user
        visit "/"
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        expect(page).not_to have_content "Please log in"
        expect(page).to have_content "New Project"
      end
    end
  end
end
