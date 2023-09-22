# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WelcomeController", stub_mediaflux: true do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "Welcome to the TigerData user portal"
      expect(page).to have_content "Log In"
    end
  end

  context "authenticated user" do
    let(:sponsor_user) { FactoryBot.create(:user, uid: "pul123") }
    let(:other_user) { FactoryBot.create(:user, uid: "zz123") }
    before do
      Project.create(metadata: { data_sponsor: "pul123", title: "project 111" })
    end

    context "for a user with sponsored projects" do
      it "shows the 'Log Out' button" do
        sign_in sponsor_user
        visit "/"
        expect(page).not_to have_content "Please log in"
        expect(page).to have_content "Log Out"
      end
      it "shows the user sponsored projects" do
        sign_in sponsor_user
        visit "/"
        expect(page).to have_content "My Sponsored Projects"
        expect(page).to have_content "project 111"
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
