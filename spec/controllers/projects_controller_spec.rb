# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectsController, type: ["controller", "feature"] do
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

      it "renders the project metadata as xml" do
        project = FactoryBot.create :project, project_id: "abc-123"
        get :details, params: { id: project.id, format: :xml }
        expect(response.content_type).to eq("application/xml; charset=utf-8")
        expect(response.body).to eq(
        "<?xml version=\"1.0\"?>\n" \
        "<request xmlns:tigerdata=\"http://tigerdata.princeton.edu\">\n" \
        "  <service name=\"asset.create\">\n" \
        "    <args>\n" \
        "      <name>#{project.project_directory_short}</name>\n" \
        "      <namespace>#{project.project_directory}NS</namespace>\n" \
        "      <meta>\n" \
        "        <tigerdata:project>\n" \
        "          <ProjectDirectory>#{project.project_directory}</ProjectDirectory>\n" \
        "          <Title>#{project.metadata[:title]}</Title>\n" \
        "          <Description>#{project.metadata[:description]}</Description>\n" \
        "          <Status>#{project.metadata[:status]}</Status>\n" \
        "          <DataSponsor>#{project.metadata[:data_sponsor]}</DataSponsor>\n" \
        "          <DataManager>#{project.metadata[:data_manager]}</DataManager>\n" \
        "          <Department>77777</Department>\n" \
        "          <Department>88888</Department>\n" \
        "          <CreatedOn>#{Mediaflux::Time.format_date_for_mediaflux(project.metadata[:created_on])}</CreatedOn>\n" \
        "          <CreatedBy>#{project.metadata[:created_by]}</CreatedBy>\n" \
        "          <ProjectID>abc-123</ProjectID>\n" \
        "          <StorageCapacity>\n" \
        "            <Size>500</Size>\n" \
        "            <Unit>GB</Unit>\n" \
        "          </StorageCapacity>\n" \
        "          <Performance Requested=\"standard\">standard</Performance>\n" \
        "          <Submission>\n" \
        "            <RequestedBy>#{project.metadata[:created_by]}</RequestedBy>\n" \
        "            <RequestDateTime>#{Mediaflux::Time.format_date_for_mediaflux(project.metadata[:created_on])}</RequestDateTime>\n" \
        "          </Submission>\n" \
        "          <ProjectPurpose>research</ProjectPurpose>\n" \
        "          <SchemaVersion>0.6.1</SchemaVersion>\n" \
        "        </tigerdata:project>\n" \
        "      </meta>\n" \
        "      <quota>\n" \
        "        <allocation>500 GB</allocation>\n" \
        "        <description>Project Quota</description>\n" \
        "      </quota>\n" \
        "      <collection cascade-contained-asset-index=\"true\" contained-asset-index=\"true\" unique-name-index=\"true\">true</collection>\n" \
        "      <type>application/arc-asset-collection</type>\n" \
        "      <pid>path=/td-test-001/test/tigerdata</pid>\n" \
        "    </args>\n" \
        "  </service>\n" \
        "</request>\n"
      )
      end
    end
  end
  describe "#create" do
    context "a signed in user" do
      let(:user) { FactoryBot.create :user }
      before do
        sign_in user
      end
      it "creates one provenance event only" do
        post :create, params: {
          "data_sponsor" => user.uid, "data_manager" => user.uid, "departments" => ["RDSS"],
          "project_directory" => "testparams", "title" => "Params",
          "description" => "testing controller params", "ro_user_counter" => "0",
          "rw_user_counter" => "0", "controller" => "projects", "action" => "create"
        }
        project = Project.last
        expect(project.provenance_events.count).to eq 2
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

      it "does not contact mediaflux" do
        allow(Mediaflux::QueryRequest).to receive(:new).and_call_original

        get :show, params: { id: project.id }

        expect(Mediaflux::QueryRequest).not_to have_received(:new)
        expect(response.body).to eq("")
      end

      context "the project is saved to mediaflux", connect_to_mediaflux: true do
        let(:user) { FactoryBot.create :user, mediaflux_session: SystemUser.mediaflux_session }
        let(:project) { FactoryBot.create :project_with_doi }
        before do
          project.save_in_mediaflux(user: user)
        end
        it "runs a query" do
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

            expect { get :show, params: { id: project.id } }.to raise_error(Mediaflux::SessionExpired)
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

  context "when the project show views are rendered for an existing project" do
    # Views are stubbed by default for rspec-rails
    # https://rspec.info/features/6-0/rspec-rails/controller-specs/isolation-from-views/
    render_views
    let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
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

  context "when the project edit views are rendered for an existing project" do
    # Views are stubbed by default for rspec-rails
    # https://rspec.info/features/6-0/rspec-rails/controller-specs/isolation-from-views/
    render_views
    let(:current_user) { FactoryBot.create(:superuser, uid: "pul123") }
    let(:approved_project) do
      project = FactoryBot.create(:approved_project, data_sponsor: current_user.uid, data_manager: current_user.uid, title: "project 111")
      project.mediaflux_id = nil
      project
    end

    before do
      approved_project
      sign_in(current_user)
    end

    it "shows the affiliation name (instead the internal code) on the project edit views" do
      get :edit, params: { id: approved_project.id }
      expect(response).to render_template("edit")
      expect(response.body).to have_content("Astrophysical Sciences")
        .or(have_content("High Performance Computing"))
        .or(have_content("Research Data and Scholarship Services"))
        .or(have_content("Princeton Research Data Service"))
        .or(have_content("Princeton Plasma Physics Laboratory"))
    end
  end
end
