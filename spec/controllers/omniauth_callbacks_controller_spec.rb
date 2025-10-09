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

  describe "Disabled login for the public" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
    let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "puladmin", mediaflux_session: SystemUser.mediaflux_session) }
    let(:developer) { FactoryBot.create(:developer, uid: "root", mediaflux_session: SystemUser.mediaflux_session) }

    context "sysadmin user" do
      it "allowed to log in when login is disabled" do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:disable_login, true)
        controller.request.env["omniauth.auth"] = double(OmniAuth::AuthHash, provider: "cas", uid: nil)
        allow(User).to receive(:from_cas) { sysadmin_user }
        get :cas
        expect(response).to redirect_to(mediaflux_passthru_path)
        test_strategy.switch!(:disable_login, false)
      end
    end

    context "developer user" do
      it "allowed to log in when login is disabled" do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:disable_login, true)
        controller.request.env["omniauth.auth"] = double(OmniAuth::AuthHash, provider: "cas", uid: nil)
        allow(User).to receive(:from_cas) { developer }
        get :cas
        expect(response).to redirect_to(mediaflux_passthru_path)
        test_strategy.switch!(:disable_login, false)
      end
    end

    context "authenticated user" do
      it "not allowed to log in when login is disabled" do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:disable_login, true)
        controller.request.env["omniauth.auth"] = double(OmniAuth::AuthHash, provider: "cas", uid: nil)
        allow(User).to receive(:from_cas) { current_user }
        get :cas
        expect(response).to redirect_to(root_path)
        test_strategy.switch!(:disable_login, false)
      end
    end
  end
end
