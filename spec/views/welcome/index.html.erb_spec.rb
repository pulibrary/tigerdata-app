# frozen_string_literal: true
require "rails_helper"

describe "home", type: :system do
  context "when on the hompage" do
    it "shows the welcome message" do
      visit "/"
      expect(page).to have_content "Welcome to\nTigerData Web Portal"
    end
  end

  context "when login is disabled" do
    it "does not display the Log In button" do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:disable_login, true)
      visit "/"
      expect(page).not_to have_css ".login-btn"
      test_strategy.switch!(:disable_login, false)
    end
  end
end
