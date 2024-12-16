# frozen_string_literal: true
require "rails_helper"

RSpec.describe "/projects", connect_to_mediaflux: true, type: :request do
  describe "POST /projects" do
    let(:data_manager) { FactoryBot.create(:user).uid }
    let(:data_sponsor) { FactoryBot.create(:user).uid }
    let(:data_user_read_only) { nil }
    let(:data_user_read_write) { nil }
    let(:departments) { nil }
    let(:description) { nil }
    let(:project_directory) { nil }
    let(:title) { nil }
    let(:params) do
      {
        data_manager: data_manager,
        data_sponsor: data_sponsor,
        data_user_read_only: data_user_read_only,
        data_user_read_write: data_user_read_write,
        departments: departments,
        description: description,
        project_directory: project_directory,
        title: title
      }
    end

    it "redirects the client to the sign in path" do
      post(projects_path, params: params)

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end

    context "when the client is authenticated" do
      let(:user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
      let(:title) { "a title" }
      let(:project_directory) { "/test-project" }

      before do
        sign_in user
      end

      it "renders a successful response" do
        post(projects_path, params: params)

        expect(response).to be_redirect
        expect(Project.all).not_to be_empty
        new_project = Project.last
        expect(response).to redirect_to(project_confirmation_path(new_project))
      end

      it "drafts a DOI when the project is valid" do
        post(projects_path, params: params)
        project = Project.last

        expect(project.metadata["project_id"]).to eq("10.34770/tbd")
      end

      it "ensures that project status is set to 'pending'" do
        post(projects_path, params: params)

        expect(response).to be_redirect
        expect(Project.all).not_to be_empty
        new_project = Project.last
        expect(new_project.status).to eq(Project::PENDING_STATUS)
      end

      context "when project is invalid" do
        let(:data_manager) { nil }

        it "does not draft a DOI when the project is invalid" do
          post(projects_path, params: params)
          expect(Project.count).to eq(0)
        end
      end

      context "multiple data users are specified" do
        let(:data_user1) { FactoryBot.create(:user, given_name: "Anonymous", family_name: "Qux", display_name: "Anonymous Qux") }
        let(:data_user2) { FactoryBot.create(:user, given_name: "Anonymous", family_name: "Foo", display_name: "Anonymous Foo") }
        let(:data_user3) { FactoryBot.create(:user, given_name: "Anonymous", family_name: "Zed", display_name: "Anonymous Zed") }
        let(:ro_user_models) do
          [
            data_user1,
            data_user2
          ]
        end
        let(:data_user_read_only) { ro_user_models.map(&:uid) }
        let(:rw_user_models) do
          [
            data_user3,
            data_user1
          ]
        end
        let(:data_user_read_write) { rw_user_models.map(&:uid) }
        let(:project_directory) { "/test-project" }
        let(:title) { "test project" }
        let(:params) do
          {
            data_manager: data_manager,
            data_sponsor: data_sponsor,
            ro_user_counter: data_user_read_only.length,
            ro_user_1: data_user_read_only.first,
            ro_user_2: data_user_read_only.last,
            rw_user_counter: data_user_read_write.length,
            rw_user_1: data_user_read_write.first,
            rw_user_2: data_user_read_write.last,
            departments: departments,
            description: description,
            project_directory: project_directory,
            title: title
          }
        end

        it "renders the data user names ordered by family name" do
          post(projects_path, params: params)

          expect(response).to be_redirect
          expect(Project.all).not_to be_empty
          new_project = Project.last
          get(project_details_path(new_project))

          expect(response.body).to include("Anonymous Foo (read only), Anonymous Qux (read only), Anonymous Zed")
        end
      end
    end
  end
end
