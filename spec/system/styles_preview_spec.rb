# frozen_string_literal: true

require "rails_helper"

describe "Styles Preview page", type: :system, connect_to_mediaflux: false, js: true do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/styles_preview"
      expect(page).to have_content "Log in"
    end
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
    it "shows the Styles Preview message" do
      sign_in current_user
      visit "/styles_preview"
      expect(page).to have_content "This page shows the styles that have been implemented for this site's look and feel."
    end
  end
end
