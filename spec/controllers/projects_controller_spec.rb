# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectsController do
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

      it "renders the project metadata as xml" do
        project = FactoryBot.create :project, project_id: "abc-123"
        get :show, params: { id: project.id, format: :xml }
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
        "          <CreatedOn>#{MediafluxTime.format_date_for_mediaflux(project.metadata[:created_on])}</CreatedOn>\n" \
        "          <CreatedBy>#{project.metadata[:created_by]}</CreatedBy>\n" \
        "          <ProjectID>abc-123</ProjectID>\n" \
        "          <StorageCapacity>\n" \
        "            <Size>500</Size>\n" \
        "            <Unit>GB</Unit>\n" \
        "          </StorageCapacity>\n" \
        "          <Performance Requested=\"standard\">standard</Performance>\n" \
        "          <Submission>\n" \
        "            <RequestedBy>#{project.metadata[:created_by]}</RequestedBy>\n" \
        "            <RequestDateTime>#{MediafluxTime.format_date_for_mediaflux(project.metadata[:created_on])}</RequestDateTime>\n" \
        "          </Submission>\n" \
        "          <ProjectPurpose>research</ProjectPurpose>\n" \
        "          <SchemaVersion>0.6.1</SchemaVersion>\n" \
        "        </tigerdata:project>\n" \
        "      </meta>\n" \
        "      <collection cascade-contained-asset-index=\"true\" contained-asset-index=\"true\" unique-name-index=\"true\">true</collection>\n" \
        "      <type>application/arc-asset-collection</type>\n" \
        "      <pid>path=/td-test-001/tigerdata</pid>\n" \
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
end
