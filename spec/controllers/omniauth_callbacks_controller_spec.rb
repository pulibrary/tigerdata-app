# frozen_string_literal: true
require "rails_helper"

RSpec.describe Users::OmniauthCallbacksController do
  before { request.env["devise.mapping"] = Devise.mappings[:user] }

  context "with project sponsor user" do
    let(:project_sponsor) { FactoryBot.create(:project_sponsor) }
    it "redirects to home page with notice" do
      allow(User).to receive(:from_cas) { project_sponsor }
      get :cas
      expect(response).to redirect_to(mediaflux_passthru_path)
    end
  end

  context "unknown user" do
    it "redirects to the homepage with alert" do
      controller.request.env["omniauth.auth"] = double(OmniAuth::AuthHash, provider: "cas", uid: nil)
      allow(User).to receive(:from_cas) { nil }
      get :cas
      expect(response).to redirect_to(root_path)
      expect(flash.notice).to eq("You can not be signed in at this time.")
    end
  end

  context "non-CAS user" do
    it "redirects to the home page with alert" do
      controller.request.env["omniauth.auth"] = double(OmniAuth::AuthHash, provider: "other", uid: nil)
      allow(User).to receive(:from_cas) { nil }
      get :cas
      expect(response).to redirect_to(root_path)
      expect(flash.alert).to eq("You are not a recognized CAS user.")
    end
  end

  describe "Disabled login for the public", type: :system, connect_to_mediaflux: false, js: true do
    let(:current_user) { FactoryBot.create(:user, uid: "tigerdatatester") }
    let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "puladmin", mediaflux_session: SystemUser.mediaflux_session) }
    let(:developer) { FactoryBot.create(:developer, uid: "root", mediaflux_session: SystemUser.mediaflux_session) }

    context "unauthenticated user" do
      it "does not show the log in button but shows the maintenance message" do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:disable_login, true)
        visit "/"
        expect(page).not_to have_css("#homepage-login")
        expect(page).to have_content("TigerData is temporarily unavailable")
        test_strategy.switch!(:disable_login, false)
      end
    end

    context "sysadmin user" do
      it "allowed to log in when login is disabled" do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:disable_login, true)
        sign_in sysadmin_user
        visit "/dashboard"
        expect(page).to have_content("puladmin (public login disabled)")
        test_strategy.switch!(:disable_login, false)
      end
      it "shows the user menu with warning for logged in sysadmin" do
        sign_in sysadmin_user
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:disable_login, true)
        visit "/dashboard"
        expect(page).to have_content("puladmin (public login disabled)")
        test_strategy.switch!(:disable_login, false)
      end
    end

    context "developer user" do
      it "allowed to log in when login is disabled" do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:disable_login, true)
        sign_in developer
        visit "/dashboard"
        expect(page).to have_content("root (public login disabled)")
        test_strategy.switch!(:disable_login, false)
      end
      it "shows the user menu with warning for logged in sysadmin" do
        sign_in developer
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:disable_login, true)
        visit "/dashboard"
        expect(page).to have_content("root (public login disabled)")
        test_strategy.switch!(:disable_login, false)
      end
    end
  end
end
