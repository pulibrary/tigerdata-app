# frozen_string_literal: true
require "rails_helper"

RSpec.describe "new-project/review-submit", type: :request do
  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:new_project_request_wizard, true)
  end

  describe "GET" do
    it "redirects the client to the sign in path" do
      get new_project_review_and_submit_url(1)

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end
    context "when the client is authenticated" do
      let(:user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
      let(:request) { Request.create(request_title: "abc123", project_title: "new project") }

      it "renders a successful response" do
        sign_in user
        get new_project_review_and_submit_url(request.id)
        expect(response).to be_successful
        expect(response.body).to include("new project")
      end
    end
  end

  describe "PUT /save" do
    it "redirects the client to the sign in path" do
      put new_project_review_and_submit_save_url(request_id: 1)

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end
    context "when the client is authenticated" do
      let(:user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }

      context "the request exists" do
        let(:request) { Request.create(request_title: "abc123", project_title: "project") }
        it "renders a successful response for a save commit" do
          sign_in user
          put new_project_review_and_submit_save_url(request.id, request: { request_title: "new title", project_title: "new project",
                                                                            state: "draft", data_sponsor: "sponsor", data_manager: "manager",
                                                                            departments: [{ "code" => "dept", "name" => "department" }.to_json, { "code" => "dept2", "name" => "two" }.to_json],
                                                                            description: "descr", parent_folder: "parent", project_folder: "folder",
                                                                            project_id: "doi", quota: "500 GB", requested_by: "uid" }, commit: "Save")
          expect(response).to redirect_to("#{requests_path}/#{request.id}")
          request.reload
          expect(request.request_title).to eq("new title")
          expect(request.project_title).to eq("new project")
          expect(request.state).to eq("draft")
          expect(request.data_sponsor).to eq("sponsor")
          expect(request.data_manager).to eq("manager")
          expect(request.departments).to eq([{ "code" => "dept", "name" => "department" }, { "code" => "dept2", "name" => "two" }])
          expect(request.description).to eq("descr")
          expect(request.parent_folder).to eq("parent")
          expect(request.project_folder).to eq("folder")
          expect(request.project_id).to eq("doi")
          expect(request.quota).to eq("500 GB")
          expect(request.requested_by).to eq("uid")
        end

        it "renders a successful response for a next commit" do
          sign_in user
          put new_project_review_and_submit_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Next")
          expect(response).to redirect_to("#{requests_path}/#{request.id}")
          request.reload
          expect(request.request_title).to eq("new title")
          expect(request.project_title).to eq("new project")
        end

        it "renders a successful response for a back commit" do
          sign_in user
          put new_project_review_and_submit_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Back")
          expect(response).to redirect_to(new_project_additional_information_related_resources_url(request))
          request.reload
          expect(request.request_title).to eq("new title")
          expect(request.project_title).to eq("new project")
        end
      end
    end
  end
end
