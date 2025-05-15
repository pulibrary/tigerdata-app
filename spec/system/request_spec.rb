# frozen_string_literal: true

require "rails_helper"

describe "New Project Request page", type: :system, connect_to_mediaflux: false, js: true do
  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:new_project_request_wizard, true)
  end

  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/requests"
      expect(page).to have_content "Log in"
    end
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
    it "shows the New Project Requests page" do
      sign_in current_user
      visit "/requests"
      expect(page).to have_content "New Project Requests"
    end
    let(:request) { Request.create(request_title: "abc123", project_title: "project") }
    it "shows the approve button on a single request view" do 
      sign_in current_user
      put new_project_review_and_submit_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Save")
      expect(page).to have_content "Approve request"
    end 
      
  end
end
