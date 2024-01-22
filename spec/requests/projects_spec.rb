# frozen_string_literal: true
require "rails_helper"

RSpec.describe "/projects", type: :request do
  describe "POST /projects" do
    let(:data_manager) { FactoryBot.create(:user).uid }
    let(:data_sponsor) { FactoryBot.create(:user).uid }
    let(:data_user_read_only) { nil }
    let(:data_user_read_write) { nil }
    let(:departments) { nil }
    let(:description) { nil }
    let(:directory) { nil }
    let(:title) { nil }
    let(:params) do
      {
        data_manager: data_manager,
        data_sponsor: data_sponsor,
        data_user_read_only: data_user_read_only,
        data_user_read_write: data_user_read_write,
        departments: departments,
        description: description,
        directory: directory,
        title: title
      }
    end

    it "redirects the client to the sign in path" do
      post(projects_path, params: params)

      expect(response).to be_redirect
      expect(response).to redirect_to(new_user_session_path)
    end

    context "when the client is authenticated" do
      let(:user) { FactoryBot.create(:user, uid: "pul123") }
      let(:response_body) do
        filename = Rails.root.join("spec", "fixtures", "files", "version_response.xml")
        File.new(filename).read
      end

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
        let(:directory) { "/test-project" }
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
            directory: directory,
            title: title
          }
        end

        it "renders the data user names ordered by family name" do
          post(projects_path, params: params)

          expect(response).to be_redirect
          expect(Project.all).not_to be_empty
          new_project = Project.last
          get(project_path(new_project))

          expect(response.body).to include("Anonymous Foo (read only), Anonymous Qux (read only), Anonymous Zed")
        end
      end
    end
  end

  describe "POST /projects/:id/approve" do
    let(:user) { FactoryBot.create(:user, uid: "pul123") }
    let(:data_manager) { FactoryBot.create(:user, uid: "test3") }
    let(:data_sponsor) { FactoryBot.create(:user, uid: "test4") }

    let(:project) do
      FactoryBot.create(:project,
                        metadata: {
                          title: "foo",
                          directory: "big-data",
                          departments: ["RDSS"],
                          description: "test2",
                          data_manager: data_manager.uid,
                          data_sponsor: data_sponsor.uid,
                          created_by: "pul123",
                          created_on: "07-Dec-2023 17:22:22"
                        })
    end
    let(:mediaflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }
    let(:mediaflux_login_fixture_path) do
      Rails.root.join("spec", "fixtures", "files", "login_response.xml")
    end
    let(:mediaflux_login_body) do
      File.read(mediaflux_login_fixture_path)
    end
    let(:mediaflux_create_fixture_path) do
      Rails.root.join("spec", "fixtures", "files", "asset_create_response.xml")
    end
    let(:mediaflux_create_body) do
      File.read(mediaflux_create_fixture_path)
    end
    let(:store) { instance_double(Store) }

    before do
      allow(store).to receive(:name).and_return("test")
      allow(Store).to receive(:all).and_return([store])

      stub_request(:post, mediaflux_url).to_return(
        {
          status: 200,
          body: mediaflux_login_body
        },
        {
          status: 200,
          body: mediaflux_create_body
        }
      )

      project
      sign_in(user)
    end

    context "when the client is authenticated" do
      let(:create_project_body) do
        <<-XML
<?xml version="1.0"?>
<request xmlns:tigerdata="http://tigerdata.princeton.edu">
  <service name="asset.create" session="sessiontoken">
    <args>
      <name>big-data</name>
      <namespace>/td-test-001/big-data-ns</namespace>
      <meta>
        <tigerdata:project>
          <code>big-data</code>
          <title>foo</title>
          <description>test2</description>
          <data_sponsor>test4</data_sponsor>
          <data_manager>test3</data_manager>
          <departments>RDSS</departments>
          <created_on>07-Dec-2023 17:22:22</created_on>
          <created_by>pul123</created_by>
        </tigerdata:project>
      </meta>
      <collection cascade-contained-asset-index="true" contained-asset-index="true" unique-name-index="true">true</collection>
      <type>application/arc-asset-collection</type>
    </args>
  </service>
</request>
XML
      end

      context "when a namespace is specified" do
        let(:project) do
          FactoryBot.create(:project,
                            metadata: {
                              title: "foo",
                              directory: "big-data",
                              departments: ["RDSS"],
                              description: "test2",
                              data_manager: data_manager.uid,
                              data_sponsor: data_sponsor.uid
                            })
        end
      end
    end
  end
end
