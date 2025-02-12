require 'rails_helper'

RSpec.describe "ProjectImports", type: :request do
  describe "POST /index" do
    it "redirects to sign in" do
      put project_import_path
      expect(response).to redirect_to new_user_session_path
      expect(flash[:alert]).to eq("You need to sign in or sign up before continuing.")
    end

    context "a signed in user" do
      let(:user) { FactoryBot.create :user }
      
      before do
        sign_in(user)
      end

      it "renders a successful response" do
        put project_import_path
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to eq("Access Denied")
      end
    end

    context "a sysadmin user" do
      let(:user) { FactoryBot.create :sysadmin, mediaflux_session: SystemUser.mediaflux_session}
      
      before do
        sign_in(user)
      end

      it "renders a successful response" do
        new_project = FactoryBot.create(:approved_project, project_directory: "test-request")
        new_project.mediaflux_id = nil
        ProjectMediaflux.create!(project: new_project, user:)
        new_project.destroy

        expect{ put project_import_path }.to change { Project.count }.by(1)
        expect(response).not_to redirect_to(dashboard_path)
        expect(flash[:alert]).to be_blank
      end
    end
  end
end
