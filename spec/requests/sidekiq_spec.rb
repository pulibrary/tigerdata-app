# frozen_string_literal: true
require "rails_helper"

# Test connections to the /sidekiq endpoint

RSpec.describe "/sidekiq", connect_to_mediaflux: false, type: :request do
  describe "GET /sidekiq" do
    context "not logged in" do
      it "redirects to the login page" do
        get "/sidekiq"
        expect(response).to be_redirect
      end
    end

    context "logged in user who is not a sysadmin or a developer" do
      let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }

      before do
        sign_in user
      end
      it "redirects to the login page" do
        get "/sidekiq"
        expect(response.code).to eq "404"
      end
    end
    context "logged in user who is a sysadmin" do
      let(:sysadmin) { FactoryBot.create(:sysadmin, mediaflux_session: SystemUser.mediaflux_session) }

      before do
        sign_in sysadmin
      end

      # TODO: This would require spinning up redis in test mode, which we might want to do eventually, but for now
      # let's ship a PR that protects the /sidekiq endpoint without delay
      xit "renders a successful response" do
        get "/sidekiq"
        expect(response).to be_successful
      end
    end
  end
end
