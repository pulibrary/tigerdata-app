# frozen_string_literal: true
require "rails_helper"

RSpec.describe "/projects", connect_to_mediaflux: true, type: :request do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  describe "GET /projects" do
    let(:data_manager) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
    let(:project) { FactoryBot.create(:approved_project, data_manager: data_manager.uid) }

    context "when the user is authenticated" do
      before do
        sign_in data_manager
      end

      it "provides the xml metadata for a project" do
        # project/12.xml
        get project_url(project), params: { format: :xml }
        expect(response.code).to eq "200"
        expect(response.content_type).to match "xml"
      end
    end
  end

  describe "GET /projects/:id/:id-mf" do
    let(:data_manager) { FactoryBot.create(:user, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
    let(:project) { create_project_in_mediaflux(current_user: sponsor_and_data_manager_user) }

    context "when the user is authenticated" do
      before do
        sign_in data_manager
      end

      it "provides the xml metadata for a project", :integration do
        get project_show_mediaflux_url(project), params: { format: :xml }
        expect(response.code).to eq "200"
        expect(response.content_type).to match "xml"
      end

      it "redirect to the project page when there is an error", :integration do
        # Go to a non-existing project to force an error
        get project_show_mediaflux_url("non-existing"), params: { format: :xml }
        expect(response.code).to eq "302"
      end
    end
  end
end
