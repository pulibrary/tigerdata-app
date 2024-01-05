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
    let(:sponsor_user) { FactoryBot.create(:user, uid: "pul123") }
    let(:manager_user) { FactoryBot.create(:user, uid: "jh1234") }
    let(:other_user) { FactoryBot.create(:user, uid: "zz123") }
    before do
      FactoryBot.create(:project, metadata: { data_sponsor: sponsor_user.uid, data_manager: other_user.uid, title: "project 111" })
      FactoryBot.create(:project, metadata: { data_sponsor: other_user.uid, data_manager: sponsor_user.uid, title: "project 222" })
      FactoryBot.create(:project, metadata: { data_sponsor: other_user.uid, data_manager: other_user.uid, data_user_read_only: [sponsor_user.uid], title: "project 333" })
    end

    context "for a user with sponsored projects" do
      it "shows the 'Log Out' button" do
        sign_in sponsor_user
        visit "/"
        expect(page).to have_content("Welcome, #{sponsor_user.given_name}!")
        expect(page).not_to have_content "Please log in"
        expect(page).to have_content "Log Out"
      end
      it "shows the user sponsored projects" do
        sign_in sponsor_user
        visit "/"
        expect(page).to have_content "Sponsored by Me"
        expect(page).to have_content "project 111"

        expect(page).to have_content "Managed by Me"
        expect(page).to have_content "project 222"

        expect(page).to have_content "Shared with Me"
        expect(page).to have_content "project 333"
      end
    end

    context "for a user without sponsored projects" do
      it "shows the 'Log Out' button" do
        sign_in other_user
        visit "/"
        expect(page).not_to have_content "Please log in"
        expect(page).to have_content "Log Out"
      end
      it "does not show any projects" do
        sign_in other_user
        visit "/"
        expect(page).not_to have_content "My Sponsored Projects"
      end
    end
  end
end
