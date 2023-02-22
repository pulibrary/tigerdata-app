# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WelcomeController" do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "Log In"
    end

    it "supports JS" do
      visit "/"
      click_on "Test jQuery"
      expect(page).to have_content "jQuery works!"
    end

    it "has flash messages" do
      visit "/"
      expect(page).to have_content "Under Construction"
      expect(page).to have_content "Welcome to TigerData"
    end
  end

  # context "authenticated user" do
  #   let(:user) { User.new(uid: "pul123").save }
  #   # let(:user) { FactoryBot.create :user, uid: "pul123" }
  #   before do
  #     sign_in user
  #   end
  #   it "shows the 'Log Out' button" do
  #     visit "/"
  #     expect(page).to have_content "User: pul123"
  #     expect(page).to have_content "Log Out"
  #   end
  # end
end
