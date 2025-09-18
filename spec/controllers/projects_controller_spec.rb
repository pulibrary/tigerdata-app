# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectsController, type: ["controller", "feature"] do
  let!(:sponsor_and_data_manager) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:project) { FactoryBot.create :project }

  before do
    Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
  end

  describe "#details" do
    it "renders an error when requesting json" do
      get :details, params: { id: project.id, format: :json }
      expect(response.content_type).to eq("application/json; charset=utf-8")
      expect(response.body).to eq("{\"error\":\"You need to sign in or sign up before continuing.\"}")
    end

    context "a signed in user" do
      let(:user) { FactoryBot.create :user }
      before do
        sign_in user
      end

      it "redirects to the root when the user does not have access " do
        get :details, params: { id: project.id, format: :json }
        expect(response).to redirect_to "http://test.host/dashboard"
      end

      context "a user who has project access" do
        let(:user) { User.find_by(uid: project.metadata_model.data_sponsor) }

        it "renders the project metadata as json" do
          get :details, params: { id: project.id, format: :json }
          expect(response.content_type).to eq("application/json; charset=utf-8")
          expect(JSON.parse(response.body)).to eq(project.metadata)
        end

        it "shows affiliation code as being saved to the project" do
          get :details, params: { id: project.id, format: :json }
          expect(JSON.parse(response.body)["departments"]).to include("55555")
            .or(include("66666"))
            .or(include("77777"))
            .or(include("88888"))
            .or(include("99999"))
        end

        it "renders the project metadata as xml", :integration do
          request = FactoryBot.create(:request_project)
          project = request.approve(sponsor_and_data_manager)
          get :details, params: { id: project.id, format: :xml }
          expect(response.content_type).to eq("application/xml; charset=utf-8")
          xml_doc = Nokogiri::XML(response.body)
          expect(xml_doc.xpath("/resource/title").text).to eq project.title
          expect(xml_doc.xpath("/resource/projectDirectory/projectDirectoryPath").text).to eq project.project_directory
          expect(xml_doc.xpath("/resource/description").text).to eq project.metadata[:description]
          expect(xml_doc.xpath("/resource/dataSponsor/@userID").text).to eq project.metadata[:data_sponsor]
          expect(xml_doc.xpath("/resource/dataManager/@userID").text).to eq project.metadata[:data_manager]
          expect(xml_doc.xpath("/resource/projectID").text).to eq project.metadata[:project_id]
        end

        it "renders the Mediaflux metadata as xml", :integration do
          request = FactoryBot.create(:request_project)
          project = request.approve(sponsor_and_data_manager)
          get :show_mediaflux, params: { id: project.id, format: :xml }
          expect(response.content_type).to eq("application/xml; charset=utf-8")
          xml_doc = Nokogiri::XML(response.body)
          expect(xml_doc.xpath("/meta//Title").text).to eq project.title
          expect(xml_doc.xpath("/meta//ProjectDirectory").text).to eq project.project_directory
          expect(xml_doc.xpath("/meta//Description").text).to eq project.metadata[:description]
          expect(xml_doc.xpath("/meta//DataSponsor").text).to eq project.metadata[:data_sponsor]
          expect(xml_doc.xpath("/meta//DataManager").text).to eq project.metadata[:data_manager]
          expect(xml_doc.xpath("/meta//ProjectID").text).to eq project.metadata[:project_id]
        end
      end
    end
  end

  describe "#index" do
    it "redirects to signin" do
      get :index
      expect(response).to redirect_to "http://test.host/sign_in"
    end

    context "a signed in user" do
      let(:user) { FactoryBot.create :user }
      before do
        sign_in user
      end
      it "redirects to root" do
        get :index
        expect(response).to redirect_to "http://test.host/dashboard"
      end
    end

    context "a signed in sysadmin user" do
      let(:user) { FactoryBot.create :sysadmin }
      before do
        sign_in user
      end
      it "redirects to root" do
        get :index
        expect(response).to render_template("index")
      end
    end
  end

  describe "#list_contents" do
    it "renders an error when requesting json" do
      get :list_contents, params: { id: project.id, format: :json }
      expect(response.content_type).to eq("application/json; charset=utf-8")
      expect(response.body).to eq("{\"error\":\"You need to sign in or sign up before continuing.\"}")
    end

    context "a signed in user" do
      let(:user) { FactoryBot.create :user }
      before do
        sign_in user
      end

      it "redirects to the root when the user does not have access " do
        get :list_contents, params: { id: project.id, format: :json }
        expect(response).to redirect_to "http://test.host/dashboard"
      end
    end
  end

  describe "#content" do
    it "renders an error when requesting json" do
      get :show, params: { id: project.id, format: :json }
      expect(response.content_type).to eq("application/json; charset=utf-8")
      expect(response.body).to eq("{\"error\":\"You need to sign in or sign up before continuing.\"}")
    end

    context "a signed in user" do
      let(:user) { FactoryBot.create :user }
      before do
        sign_in user
      end

      it "redirects to the root when the user does not have access " do
        get :show, params: { id: project.id }
        expect(response).to redirect_to "http://test.host/dashboard"
      end

      context "a user who has project access" do
        let(:user) { User.find_by(uid: project.metadata_model.data_sponsor) }

        it "does not contact mediaflux" do
          allow(Mediaflux::QueryRequest).to receive(:new).and_call_original

          get :show, params: { id: project.id }

          expect(Mediaflux::QueryRequest).not_to have_received(:new)
          expect(response.body).to eq("")
        end

        context "the project is saved to mediaflux", connect_to_mediaflux: true, integration: true do
          let(:project) do
            request = FactoryBot.create(:request_project)
            project = request.approve(sponsor_and_data_manager)
            project
          end
          it "runs a query" do
            sign_in sponsor_and_data_manager
            allow(Mediaflux::QueryRequest).to receive(:new).and_call_original

            get :show, params: { id: project.id }

            expect(Mediaflux::QueryRequest).to have_received(:new)
          end
          context "the session expires for an active web user" do
            let(:original_session) { SystemUser.mediaflux_session }

            before do
              allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
              allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:mediaflux_session).and_return(original_session)
              allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:active_web_user).and_return(true)
            end
            it "gets a new session if the session expires" do
              Mediaflux::LogoutRequest.new(session_token: original_session).resolve

              get :show, params: { id: project.id }

              expect(response).to redirect_to "http://test.host/mediaflux_passthru?path=%2Fprojects%2F#{project.id}"
            end
          end

          context "the session expires for the system user" do
            let(:original_session) { SystemUser.mediaflux_session }

            before do
              allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
              allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:mediaflux_session).and_return(original_session)
              allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:active_web_user).and_return(false)
            end
            it "gets a new session if the session expires" do
              Mediaflux::LogoutRequest.new(session_token: original_session).resolve

              expect { get :show, params: { id: project.id } }.to raise_error(Mediaflux::SessionExpired, /Session expired for token/)
            end
          end

          context "the system user password is bad" do
            before do
              @original_pass = Rails.configuration.mediaflux["api_password"]
            end

            after do
              Rails.configuration.mediaflux["api_password"] = @original_pass
            end

            it "gets a new session if the session expires" do
              Rails.configuration.mediaflux["api_password"] = "badpass"
              expect do
                get :show, params: { id: project.id }
              end.to raise_error(Mediaflux::SessionError)
            end
          end
        end
      end
    end
  end

  context "when the project show views are rendered for an existing project" do
    # Views are stubbed by default for rspec-rails
    # https://rspec.info/features/6-0/rspec-rails/controller-specs/isolation-from-views/
    render_views
    let(:current_user) { sponsor_and_data_manager }
    let(:project) { FactoryBot.create(:project, data_sponsor: current_user.uid, data_manager: current_user.uid, title: "project 111") }

    before do
      project
      sign_in(current_user)
    end

    it "shows the affiliation name (instead the internal code) on the project show views" do
      get :details, params: { id: project.id }
      expect(response).to render_template("details")
      expect(response.body).to have_content("Astrophysical Sciences")
        .or(have_content("High Performance Computing"))
        .or(have_content("Research Data and Scholarship Services"))
        .or(have_content("Princeton Research Data Service"))
        .or(have_content("Princeton Plasma Physics Laboratory"))
    end
  end
end
