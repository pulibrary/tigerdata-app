# frozen_string_literal: true
require "rails_helper"
RSpec.describe RequestsController, type: :controller do
  let(:session_token) { Mediaflux::LogonRequest.new.session_token }
  let(:current_user) { FactoryBot.create(:sysadmin, uid: "tigerdatatester") }
  let(:valid_request) do
    Request.create(project_title: "Valid Request", data_sponsor: current_user.uid, data_manager: current_user.uid, departments: [{ code: "dept", name: "department" }],
                   quota: "500 GB", description: "A valid request",
                   parent_folder: "parent",
                   project_folder: random_project_directory, project_purpose: "research")
  end

  describe "#approve" do
    it "redirects to sign in if no user is logged in" do
      get :approve, params: { id: valid_request.id }
      expect(response).to redirect_to "http://test.host/sign_in"
    end

    context "a signed in sysadmin user" do
      let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "tigerdatatester") }
      let(:valid_request) do
        Request.create(project_title: "Valid Request", data_sponsor: sysadmin_user.uid, data_manager: sysadmin_user.uid, departments: [{ code: "dept", name: "department" }],
                       quota: "500 GB", description: "A valid request",
                       parent_folder: "parent",
                       project_folder: random_project_directory, project_purpose: "research")
      end
      before do
        sign_in sysadmin_user
      end

      it "approves the request" do
        valid_request # make sure the request exists before we start the count
        expect { get :approve, params: { id: valid_request.id } }.to change { Project.count }.by(1).and change { Request.count }.by(-1)
      end

      context "the production environment" do
        before do
          allow(Rails.env).to receive(:production?).and_return(true)
        end

        it "approves the request" do
          valid_request # make sure the request exists before we start the count
          expect { get :approve, params: { id: valid_request.id } }.to change { Project.count }.by(1).and change { Request.count }.by(-1)
        end
      end
    end

    context "a non elevated user" do
      let(:researcher_user) { FactoryBot.create(:user) }
      let(:valid_request) do
        Request.create(project_title: "Valid Request", data_sponsor: researcher_user.uid, data_manager: researcher_user.uid, departments: [{ code: "dept", name: "department" }],
                       quota: "500 GB", description: "A valid request",
                       parent_folder: "parent",
                       project_folder: random_project_directory, project_purpose: "research")
      end
      before do
        sign_in researcher_user
      end

      it "does not approve the request" do
        valid_request # make sure the request exists before we start the count
        expect { get :approve, params: { id: valid_request.id } }.to change { Project.count }.by(0).and change { Request.count }.by(0)
        expect(response).to redirect_to "http://test.host/dashboard"
      end

      context "the production environment" do
        before do
          allow(Rails.env).to receive(:production?).and_return(true)
        end

        it "does not approve the request" do
          valid_request # make sure the request exists before we start the count
          expect { get :approve, params: { id: valid_request.id } }.to change { Project.count }.by(0).and change { Request.count }.by(0)
          expect(response).to redirect_to "http://test.host/dashboard"
        end
      end
    end

    context "a tester trainer" do
      let(:trainer_user) { FactoryBot.create(:trainer, uid: "tigerdatatester") }
      let(:valid_request) do
        Request.create(project_title: "Valid Request", data_sponsor: trainer_user.uid, data_manager: trainer_user.uid, departments: [{ code: "dept", name: "department" }],
                       quota: "500 GB", description: "A valid request",
                       parent_folder: "parent",
                       project_folder: random_project_directory, project_purpose: "research")
      end
      before do
        sign_in trainer_user
      end

      it "does not approve the request" do
        valid_request # make sure the request exists before we start the count
        expect { get :approve, params: { id: valid_request.id } }.to change { Project.count }.by(0).and change { Request.count }.by(0)
        expect(response).to redirect_to "http://test.host/dashboard"
      end

      it "approves the request if they are emulating a sysadmin" do
        allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
        allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:emulation_role).and_return("System Administrator")
        valid_request # make sure the request exists before we start the count
        expect { get :approve, params: { id: valid_request.id } }.to change { Project.count }.by(1).and change { Request.count }.by(-1)
      end

      context "the production environment" do
        before do
          allow(Rails.env).to receive(:production?).and_return(true)
        end

        it "does not approve the request" do
          valid_request # make sure the request exists before we start the count
          expect { get :approve, params: { id: valid_request.id } }.to change { Project.count }.by(0).and change { Request.count }.by(0)
          expect(response).to redirect_to "http://test.host/dashboard"
        end
      end
    end

    context "a developer" do
      let(:developer) { FactoryBot.create(:developer, uid: "tigerdatatester") }
      let(:valid_request) do
        Request.create(project_title: "Valid Request", data_sponsor: developer.uid, data_manager: developer.uid, departments: [{ code: "dept", name: "department" }],
                       quota: "500 GB", description: "A valid request",
                       parent_folder: "parent",
                       project_folder: random_project_directory, project_purpose: "research")
      end
      before do
        sign_in developer
      end

      it "approves the request" do
        allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
        allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:emulation_role).and_return("System Administrator")
        valid_request # make sure the request exists before we start the count
        expect { get :approve, params: { id: valid_request.id } }.to change { Project.count }.by(1).and change { Request.count }.by(-1)
      end

      context "the production environment" do
        before do
          allow(Rails.env).to receive(:production?).and_return(true)
        end

        it "does not approve the request" do
          valid_request # make sure the request exists before we start the count
          expect { get :approve, params: { id: valid_request.id } }.to change { Project.count }.by(0).and change { Request.count }.by(0)
          expect(response).to redirect_to "http://test.host/dashboard"
        end
      end
    end
  end

  context "when a session expires" do
    let(:original_session) { SystemUser.mediaflux_session }
    let(:researcher_user) { FactoryBot.create(:sysadmin, uid: "tigerdatatester") }
    let(:valid_request) do
      Request.create(project_title: "Valid Request", data_sponsor: researcher_user.uid, data_manager: researcher_user.uid, departments: [{ code: "dept", name: "department" }],
                     quota: "500 GB", description: "A valid request",
                     parent_folder: "parent",
                     project_folder: random_project_directory, project_purpose: "research")
    end

    before do
      sign_in researcher_user
      allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
      allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:mediaflux_session).and_return(original_session)
      allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:active_web_user).and_return(true)
    end

    it "and a ProjectCreateError is thrown" do
      Mediaflux::LogoutRequest.new(session_token: original_session).resolve
      valid_request
      allow(Request).to receive(:find).and_return(valid_request)
      allow(valid_request).to receive(:approve).and_raise(ProjectCreate::ProjectCreateError, "Session expired for token")

      get :approve, params: { id: valid_request.id }
      expect(response).to redirect_to "http://test.host/mediaflux_passthru?path=%2Frequests%2F#{valid_request.id}%2Fapprove"
    end

    it "and a Mediaflux::SessionExpired is thrown" do
      Mediaflux::LogoutRequest.new(session_token: original_session).resolve
      valid_request
      allow(Request).to receive(:find).and_return(valid_request)
      allow(valid_request).to receive(:approve).and_raise(Mediaflux::SessionExpired, "Session expired for token")
      get :approve, params: { id: valid_request.id }
      expect(response).to redirect_to "http://test.host/mediaflux_passthru?path=%2Frequests%2F#{valid_request.id}%2Fapprove"
    end
  end
end
