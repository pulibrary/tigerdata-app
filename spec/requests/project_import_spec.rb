require 'rails_helper'

RSpec.describe "ProjectImports", type: :request do
  describe "POST /index" do
    it "redirects to sign in" do
      put project_import_path
      expect(response).to redirect_to new_user_session_path
      expect(flash[:alert]).to eq("You need to sign in or sign up before continuing.")
    end

    it "redirects to sign in" do
      get project_import_path
      expect(response).to redirect_to new_user_session_path
      expect(flash[:alert]).to eq("You need to sign in or sign up before continuing.")
    end

      context "a signed in user" do
      let(:user) { FactoryBot.create :user }
      
      before do
        sign_in(user)
      end

      it "redirects to dashboard with access denied" do
        put project_import_path
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to eq("Access Denied")
      end

      it "renders the dashboard with no message" do
        get project_import_path
        expect(response.body).to include("Welcome")
        expect(flash[:alert]).to be_blank
      end
    end

    context "a sysadmin user" do
      let(:user) { FactoryBot.create :sysadmin, mediaflux_session: SystemUser.mediaflux_session, eligible_sponsor:true }
      
      before do
        sign_in(user)
      end

      it "renders a successful response" do
        expect{ put project_import_path }.to change { Project.count }.by(0)
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to eq "Created 0 projects."
      end

      it "renders a successful response" do
        new_project = FactoryBot.create(:approved_project, project_directory: "test-request")
        new_project.mediaflux_id = nil
        ProjectMediaflux.create!(project: new_project, user:)
        new_project.destroy

        expect{ put project_import_path }.to change { Project.count }.by(1)
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to eq "Created 1 project."
      end

      it "renders a successful response with any errors" do
        new_project = FactoryBot.create(:approved_project, project_directory: "test-request")
        new_project.mediaflux_id = nil
        ProjectMediaflux.create!(project: new_project, user:)

        expect{ put project_import_path }.to change { Project.count }.by(0)
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to eq "Created 0 projects. The following errors occurred: <ul><li>Skipping project 10.34770/tbd.  There are already 1 version of that project in the system</li><ul>"
      end
    end
  end
end
