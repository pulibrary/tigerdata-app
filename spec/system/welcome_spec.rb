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

  # Fails because it requires access to MediaFlux
  # (the welcome controller now fetches some data once a user has logged in)
  #
  # Commented until we figure out how to mock MediaFlux
  #
  # context "authenticated user" do
  #   let(:user) { FactoryBot.create(:user, uid: "pul123") }
  #   before do
  #     sign_in user
  #   end
  #   it "shows the 'Log Out' button" do
  #     visit "/"
  #     expect(page).not_to have_content "Please log in"
  #     expect(page).to have_content "Log Out"
  #   end
  # end
end
