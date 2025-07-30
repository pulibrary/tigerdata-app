require 'rails_helper'

RSpec.describe "ProjectImports", type: :request do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }

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

      it "renders a successful response",
      :integration do
        # Create the project in the Rails database and in Mediaflux
        # (and then delete it from the Rails database)
        new_project = FactoryBot.create(:approved_project)
        new_project.approve!(current_user: user)
        new_project.destroy

        # The new project will be imported because we deleted it from the Rail database
        put project_import_path
        expect(response).to render_template(:run)
        expect(flash[:notice].match?(/Created\s\d*\sproject/)).to be true
        expect(response.body).to include("Created project for #{new_project.metadata_model.project_id}")
      end

      it "renders a successful response with any errors",
      :integration do
        # Create the project in the Rails database and in Mediaflux
        new_project = FactoryBot.create(:approved_project)
        new_project.approve!(current_user: user)

        # The import will detect that the project is already in the database
        put project_import_path
        expect(response).to render_template(:run)
        expect(response.body).to include("Skipping project #{new_project.metadata_model.project_id}.")
      end
    end
  end
end
