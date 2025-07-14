require 'rails_helper'

RSpec.describe "ProjectImports", type: :request do
  let!(:hc_user) { FactoryBot.create(:project_sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }

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
        new_project = FactoryBot.create(:approved_project, project_directory: random_project_directory)
        new_project.mediaflux_id = nil
        ProjectMediaflux.create!(project: new_project, user:)
        new_project.destroy

        # Because in Mediaflux we are using the same namespace gor our tests and our development
        # environment (/princeton/tigerdataNS) it is possible that the import will pick up more
        # than just our one project defined above, so our test accounts for 1 or more projects
        # being imported.
        put project_import_path
        expect(response).to render_template(:run)
        expect(flash[:notice].match?(/Created\s\d*\sproject/)).to be true
      end

      it "renders a successful response with any errors" do
        new_project = FactoryBot.create(:approved_project, project_directory: random_project_directory)
        ProjectMediaflux.create!(project: new_project, user:)

        put project_import_path
        expect(response).to render_template(:run)
        # The data in the import file includes this invalid Data Manager
        expect(response.body).to include("Invalid netid: mjc12 for role Data Manager")
      end
    end
  end
end
