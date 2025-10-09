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
      expect(response).to redirect_to(help_path)
      expect(flash.alert).to eq("You are not a recognized CAS user.")
    end
  end
end
