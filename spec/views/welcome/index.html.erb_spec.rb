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

  context "when system is under maintenance" do
    it "does not display the Log In button" do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:planned_maintenance, true)
      visit "/"
      expect(page).not_to have_css ".login-btn"
      test_strategy.switch!(:planned_maintenance, false)
    end
  end

  context "when Entra login is enabled" do
    it "includes the Entra login URL in the header" do
      test_strategy = Flipflop::FeatureSet.current.test!
      original_value = Flipflop.entra_enabled?
      test_strategy.switch!(:entra_enabled, true)

      visit "/"

      expect(page).to have_css "header form[action='TODO: fill in with real path likely user_entra_id_omniauth_authorize_path']"
      test_strategy.switch!(:entra_enabled, original_value)
    end
  end
  context "when Entra login is not enabled" do
    it "includes the CAS login URL in the header" do
      test_strategy = Flipflop::FeatureSet.current.test!
      original_value = Flipflop.entra_enabled?
      test_strategy.switch!(:entra_enabled, false)

      visit "/"

      expect(page).to have_css "header form[action='#{user_cas_omniauth_authorize_path}']"
      test_strategy.switch!(:entra_enabled, original_value)
    end
  end
end
