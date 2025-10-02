# frozen_string_literal: true
require "rails_helper"
RSpec.describe Users::MediafluxCallbacksController, type: :controller do
  let!(:user) { FactoryBot.create(:user) }

  before do
    sign_in user
  end

  describe "#passthru" do
    it "redirects to sign in if no user is logged in" do
      session[:cas_login_url] = "https://example.com"
      get :passthru
      expect(response).to redirect_to "https://example.com"
    end
  end

  describe "#cas" do
    it "redirects to the dashboard" do
      allow_any_instance_of(User).to receive(:mediaflux_login).and_return(true)
      session[:cas_validation_url] = "https://example.com?abc=123"
      get :cas, params: { ticket: "ticket123" }
      expect(response).to redirect_to dashboard_path
    end

    it "redirects to the original_path" do
      allow_any_instance_of(User).to receive(:mediaflux_login).and_return(true)
      session[:cas_validation_url] = "https://example.com?abc=123"
      session[:original_path] = user_path(user.id)
      get :cas, params: { ticket: "ticket123" }
      expect(response).to redirect_to user_path(user.id)
    end
  end
end
