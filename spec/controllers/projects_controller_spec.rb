# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectsController, type: ["controller", "feature"] do
  let(:project) { FactoryBot.create :project }
  describe "#show" do
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

      it "renders the project metadata as json" do
        get :show, params: { id: project.id, format: :json }
        expect(response.content_type).to eq("application/json; charset=utf-8")
        expect(JSON.parse(response.body)).to eq(project.metadata)
      end

      it "shows affiliation code as being saved to the project" do
        get :show, params: { id: project.id, format: :json }
        expect(JSON.parse(response.body)["departments"]).to include("23100")
          .or(include("HPC"))
          .or(include("RDSS"))
          .or(include("PRDS"))
          .or(include("PPPL"))
      end

      it "renders the project metadata as xml" do
        project = FactoryBot.create :project, project_id: "abc-123"
        get :show, params: { id: project.id, format: :xml }
        save_and_open_page
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
        "          <Department>RDSS</Department>\n" \
        "          <Department>PRDS</Department>\n" \
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

  context "shows affiliation name/title instead of code on project show page" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123") }

    before do
      FactoryBot.create(:project, data_sponsor: current_user.uid, data_manager: other_user.uid, title: "project 111")
      FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: current_user.uid, title: "project 222")
      FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: other_user.uid, data_user_read_only: [current_user.uid], title: "project 333")
      FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: other_user.uid, title: "project 444")
    end

    it "works" do
      sign_in current_user
      visit("/")
      #      project = Project.last
      # visit the show page
      # get :show, params: { id: project.id }
      # visit("/projects/" + project.id.to_s)
      expect(page).to have_content("Astrophysical Sciences")
                  .or(have_content("High Performance Computing"))
        .or(have_content("Research Data and Scholarly Services"))
        .or(have_content("Princeton Research Data Service"))
        .or(have_content("Princeton Plasma Physics Laboratory"))
    end
  end

  # it "shows affiliation name/title instead of code on project edit page" do
  # visit("/projects/" + project.id.to_s + "/edit")
  # expect(page).to have_content("Astrophysical Sciences")
  #           .or(have_content("High Performance Computing"))
  # .or(have_content("Research Data and Scholarly Services"))
  # .or(have_content("Princeton Research Data Service"))
  # .or(have_content("Princeton Plasma Physics Laboratory"))
  # end
end
