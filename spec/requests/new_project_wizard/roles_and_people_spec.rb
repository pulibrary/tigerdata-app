# frozen_string_literal: true
require "rails_helper"

RSpec.describe "new-project/roles-people", type: :request do
  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:new_project_request_wizard, true)
  end

  describe "GET" do
    it "redirects the client to the sign in path" do
      get new_project_roles_and_people_url(1)

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end
    context "when the client is authenticated" do
      let(:data_manager) { FactoryBot.create(:user, uid: "manager1") }
      let(:user) { FactoryBot.create(:sysadmin, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
      let(:request) { Request.create(data_sponsor: "pul123", data_manager: "manager1", project_title: "new project") }

      it "renders a successful response" do
        sign_in user
        get new_project_roles_and_people_url(request.id)
        expect(response).to be_successful
        expect(response.body).to include("pul123")
        expect(response.body).to include("manager1")
      end
    end
  end

  describe "PUT /save" do
    it "redirects the client to the sign in path" do
      put new_project_roles_and_people_save_url(request_id: 1)

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end
    context "when the client is authenticated" do
      let(:data_manager) { FactoryBot.create(:user, uid: "manager1") }
      let(:other_user) { FactoryBot.create(:user) }
      let(:user) { FactoryBot.create(:sysadmin, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }

      context "the request exists" do
        let(:request) { Request.create(request_title: "abc123", project_title: "project", data_sponsor: other_user.uid, data_manager: other_user.uid) }
        it "renders a successful response for a save commit" do
          sign_in user
          put new_project_roles_and_people_save_url(request.id, request: { data_sponsor: "pul123", data_manager: "manager1", project_title: "new project" }, commit: "Save")
          expect(response).to redirect_to("#{requests_path}/#{request.id}")
          request.reload
          expect(request.data_sponsor).to eq("pul123")
          expect(request.data_manager).to eq("manager1")
          expect(request.project_title).to eq("new project")
        end

        it "renders a successful response for a next commit" do
          sign_in user
          put new_project_roles_and_people_save_url(request.id, request: { data_sponsor: "pul123", project_title: "new project", data_manager: "manager1" }, commit: "Next")
          # TODO: when the wizard is fully functional the correct redirect is below
          # expect(response).to redirect_to(new_project_project_type_url(request))
          expect(response).to redirect_to(new_project_storage_and_access_path(request))
          request.reload
          expect(request.data_sponsor).to eq("pul123")
          expect(request.data_manager).to eq("manager1")
          expect(request.project_title).to eq("new project")
        end

        it "renders a successful response for a back commit" do
          sign_in user
          put new_project_roles_and_people_save_url(request.id, request: { data_sponsor: "pul123", project_title: "new project", data_manager: "manager1" }, commit: "Back")
          # TODO: when the wizard is fully functional the correct redirect is below
          # expect(response).to redirect_to(new_project_project_info_dates_url(request))
          expect(response).to redirect_to(new_project_project_info_url(request))
          request.reload
          expect(request.data_sponsor).to eq("pul123")
          expect(request.data_manager).to eq("manager1")
          expect(request.project_title).to eq("new project")
        end
      end
    end
  end
end
