# frozen_string_literal: true
require "rails_helper"

RSpec.describe "new-project/project-info-categories", type: :request do
  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:new_project_request_wizard, true)
  end

  describe "GET" do
    it "redirects the client to the sign in path" do
      get new_project_project_info_categories_url(1)

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end
    context "when the client is authenticated" do
      let(:user) { FactoryBot.create(:sysadmin, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
      let(:request) { Request.create(request_title: "abc123", project_title: "new project") }

      it "renders a successful response" do
        sign_in user
        get new_project_project_info_categories_url(request.id)
        expect(response).to be_successful
        expect(response.body).to include("new project")
      end
    end
  end

  describe "PUT /save" do
    it "redirects the client to the sign in path" do
      put new_project_project_info_categories_save_url(request_id: 1)

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end
    context "when the client is authenticated" do
      let(:user) { FactoryBot.create(:sysadmin, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }

      context "the request exists" do
        let(:request) { Request.create(request_title: "abc123", project_title: "project") }
        it "renders a successful response for a save commit" do
          sign_in user
          put new_project_project_info_categories_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Save")
          expect(response).to redirect_to("#{requests_path}/#{request.id}")
          request.reload
          expect(request.request_title).to eq("new title")
          expect(request.project_title).to eq("new project")
        end

        it "renders a successful response for a next commit" do
          sign_in user
          put new_project_project_info_categories_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Next")
          expect(response).to redirect_to(new_project_project_info_dates_url(request))
          request.reload
          expect(request.request_title).to eq("new title")
          expect(request.project_title).to eq("new project")
        end

        it "renders a successful response for a back commit" do
          sign_in user
          put new_project_project_info_categories_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Back")
          expect(response).to redirect_to(new_project_project_info_url(request))
          request.reload
          expect(request.request_title).to eq("new title")
          expect(request.project_title).to eq("new project")
        end
      end
    end
  end
end
