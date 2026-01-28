# frozen_string_literal: true
require "rails_helper"

RSpec.describe "delete request/:id", type: :request do
  describe "#delete" do
    it "redirects the client to the sign in path" do
      delete request_path(1)
      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end

    context "when the client is authenticated" do
      let(:researcher) { FactoryBot.create(:sysadmin, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
      let(:request) { NewProjectRequest.create(request_title: "abc123", project_title: "new project") }

      it "renders a redirect response" do
        sign_in researcher
        request # make sure the object exists before we try to destroy it
        expect { delete request_path(request.id) }.to change { NewProjectRequest.count }.by(0)
        expect(response).to be_redirect
        expect(response).to redirect_to(dashboard_path)
        expect(flash.notice).to eq("You do not have permission to delete the request of another user.")
      end
    end

    context "when the authenticated client is request creator" do
      let(:researcher) { FactoryBot.create(:sysadmin, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
      let(:request) { NewProjectRequest.create(request_title: "abc123", project_title: "new project", requested_by: researcher.uid) }

      it "returns json" do
        sign_in researcher
        request # make sure the object exists before we try to destroy it
        expect { delete request_path(request.id) }.to change { NewProjectRequest.count }.by(-1)
        expect(response).to be_redirect
        expect(response).to redirect_to(dashboard_path(modal: "confirm_delete_draft"))
      end
    end
  end
end
