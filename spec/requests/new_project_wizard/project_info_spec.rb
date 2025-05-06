# frozen_string_literal: true
require "rails_helper"

RSpec.describe "/new-project/project-info", type: :request do
  describe "GET" do
    it "redirects the client to the sign in path" do
      get new_project_project_info_url

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end
    context "when the client is authenticated" do
      let(:user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }

      it "renders a successful response" do
        sign_in user
        get new_project_project_info_url
        expect(response).to be_successful
      end

      context "the request exists" do
        let(:request) { Request.create(request_title: "abc123") }
        it "renders a successful response" do
          sign_in user
          get new_project_project_info_url(request.id)
          expect(response).to be_successful
          expect(response.body).to include("abc123")
        end
      end
    end
  end

  describe "PUT /save" do
    it "redirects the client to the sign in path" do
      put new_project_project_info_save_url(request_id: 1)

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end
    context "when the client is authenticated" do
      let(:user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }

      context "the request exists" do
        let(:request) { Request.create(request_title: "abc123") }
        it "renders a successful response for a save commit" do
          sign_in user
          put new_project_project_info_save_url(request.id, request: { request_title: "new title" }, commit: "Save")
          expect(response).to redirect_to(dashboard_path)
          expect(request.reload.request_title).to eq("new title")
        end

        it "renders a successful response for a next commit" do
          sign_in user
          put new_project_project_info_save_url(request.id, request: { request_title: "new title" }, commit: "Next")
          expect(response).to redirect_to(new_project_project_info_categories_path(request))
          expect(request.reload.request_title).to eq("new title")
        end

        it "renders a successful response for a back commit" do
          sign_in user
          put new_project_project_info_save_url(request.id, request: { request_title: "new title" }, commit: "Back")
          expect(response).to redirect_to(dashboard_path)
          expect(request.reload.request_title).to eq("new title")
        end
      end
    end
  end
end
