# frozen_string_literal: true
require "rails_helper"

RSpec.describe "new-project/storage-access", type: :request do
  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:new_project_request_wizard, true)
  end

  describe "GET" do
    it "redirects the client to the sign in path" do
      get new_project_storage_and_access_url(1)

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end
    context "when the client is authenticated" do
      let(:user) { FactoryBot.create(:sysadmin, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
      let(:request) { Request.create(request_title: "abc123", project_title: "new project", quota: "custom", storage_size: 23, storage_unit: "GB") }

      it "renders a successful response" do
        sign_in user
        get new_project_storage_and_access_url(request.id)
        expect(response).to be_successful
        expect(response.body).to include("value=\"23.0\"")
        expect(response.body).to include("<option value=\"GB\" selected>")
      end
    end
  end

  describe "PUT /save" do
    it "redirects the client to the sign in path" do
      put new_project_storage_and_access_save_url(request_id: 1)

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end
    context "when the client is authenticated" do
      let(:user) { FactoryBot.create(:sysadmin, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }

      context "the request exists" do
        let(:request) { Request.create(request_title: "abc123", project_title: "project", quota: "500 GB") }
        it "renders a successful response for a save commit" do
          sign_in user
          put new_project_storage_and_access_save_url(request.id, request: { request_title: "new title", project_title: "new project", quota: "2 TB" }, commit: "Save")
          expect(response).to redirect_to("#{requests_path}/#{request.id}")
          request.reload
          expect(request.request_title).to eq("new title")
          expect(request.project_title).to eq("new project")
          expect(request.quota).to eq("2 TB")
        end

        it "renders a successful response for a next commit" do
          sign_in user
          put new_project_storage_and_access_save_url(request.id, request: { request_title: "new title", project_title: "new project", quota: "2 TB" }, commit: "Next")
          # TODO: when the wizard is fully functional the correct redirect is below
          # expect(response).to redirect_to(new_project_additional_information_grants_and_funding_url(request))
          expect(response).to redirect_to(new_project_review_and_submit_url(request))
          request.reload
          expect(request.request_title).to eq("new title")
          expect(request.project_title).to eq("new project")
          expect(request.quota).to eq("2 TB")
        end

        it "renders a successful response for a back commit" do
          sign_in user
          put new_project_storage_and_access_save_url(request.id, request: { request_title: "new title", project_title: "new project", quota: "custom", storage_size: "60", storage_unit: "TB" },
                                                                  commit: "Back")
          # TODO: when the wizard is fully functional the correct redirect is below
          # expect(response).to redirect_to(new_project_project_type_url(request))
          expect(response).to redirect_to(new_project_roles_and_people_url(request))
          request.reload
          expect(request.request_title).to eq("new title")
          expect(request.project_title).to eq("new project")
          expect(request.quota).to eq("custom")
          expect(request.storage_size).to eq(60.0)
          expect(request.storage_unit).to eq("TB")
        end
      end
    end
  end
end
