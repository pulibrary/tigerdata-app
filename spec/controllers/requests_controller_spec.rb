# frozen_string_literal: true
require "rails_helper"
RSpec.describe RequestsController, type: :controller do
  let!(:current_user) { FactoryBot.create(:sysadmin, uid: "tigerdatatester") }
  let(:valid_request) do
    Request.create(project_title: "Valid Request", data_sponsor: current_user.uid, data_manager: current_user.uid, departments: [{ code: "dept", name: "department" }],
                   quota: "500 GB", description: "A valid request",
                   project_folder: "valid_folder", project_purpose: "research")
  end
  let(:session_token) { Mediaflux::LogonRequest.new.session_token }

  describe "#approve" do
    it "redirects to sign in if no user is logged in" do
      get :approve, params: { id: valid_request.id }
      expect(response).to redirect_to "http://test.host/sign_in"
    end

    context "a signed in user" do
      before do
        sign_in current_user
      end

      it "approves the request" do
        valid_request # make sure the request exists before we start the count
        expect { get :approve, params: { id: valid_request.id } }.to change { Project.count }.by(1).and change { Request.count }.by(-1)
      end
    end
  end

  context "when a session expires" do
    let(:original_session) { SystemUser.mediaflux_session }

    before do
      allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
      allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:mediaflux_session).and_return(original_session)
      allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:active_web_user).and_return(true)
    end

    it "and a ProjectCreateError is thrown" do
      sign_in current_user
      Mediaflux::LogoutRequest.new(session_token: original_session).resolve
      valid_request
      allow(Request).to receive(:find).and_return(valid_request)
      allow(valid_request).to receive(:approve).and_raise(ProjectCreate::ProjectCreateError, "Session expired for token")

      get :approve, params: { id: valid_request.id }
      expect(response).to redirect_to "http://test.host/mediaflux_passthru?path=%2Frequests%2F#{valid_request.id}%2Fapprove"
    end

    it "and a Mediaflux::SessionExpired is thrown" do
      sign_in current_user
      Mediaflux::LogoutRequest.new(session_token: original_session).resolve
      valid_request
      allow(Request).to receive(:find).and_return(valid_request)
      allow(valid_request).to receive(:approve).and_raise(Mediaflux::SessionExpired, "Session expired for token")

      get :approve, params: { id: valid_request.id }
      expect(response).to redirect_to "http://test.host/mediaflux_passthru?path=%2Frequests%2F#{valid_request.id}%2Fapprove"
    end
  end
end
