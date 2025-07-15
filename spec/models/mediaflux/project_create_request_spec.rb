# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ProjectCreateRequest, connect_to_mediaflux: true, type: :model do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  let(:create_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_create_response.xml")
    File.new(filename).read
  end

  describe "#id" do

    # Class Mediaflux::ProjectCreateRequest should be removed now that we are creating projects
    # via Mediaflux::ProjectCreateServiceRequest
    xit "sends the metadata to the server" do
      data_user_ro = FactoryBot.create :user, mediaflux_session: SystemUser.mediaflux_session
      data_user_rw = FactoryBot.create :user, mediaflux_session: SystemUser.mediaflux_session
      session_id =  data_user_ro.mediaflux_session

      created_on = Time.current.in_time_zone("America/New_York").iso8601
      project = FactoryBot.create :project, data_user_read_only: [data_user_ro.uid], data_user_read_write: [data_user_rw.uid], created_on: created_on,
                                            project_id: "abc/123", project_directory: random_project_directory,
                                            storage_capacity: { size: { requested: 700 }, unit: { requested: "TB" }.with_indifferent_access }
      create_request = described_class.new(session_token: session_id, project:, namespace: Rails.configuration.mediaflux[:api_root_ns])
      expect(create_request.response_error).to be_blank
      expect(create_request.id).not_to be_blank
      req = Mediaflux::AssetMetadataRequest.new(session_token: session_id, id: create_request.id)
      mf_metadata  = req.metadata

      expect(mf_metadata[:name]).to eq(project.metadata_model.project_directory)
      expect(mf_metadata[:title]).to eq(project.metadata_model.title)
      expect(mf_metadata[:description]).to eq(project.metadata_model.description)
      expect(mf_metadata[:data_sponsor]).to eq(project.metadata_model.data_sponsor)
      expect(mf_metadata[:departments]).to eq(project.metadata_model.departments)
      # TODO Should really utilize Mediaflux""Time, but the time class upcases the date and does not zero pad the day

      # Temporarily removing as the current project schema in mediaflux is not expecting these fields
      # expect(mf_metadata[:created_on]).to eq(Time.zone.parse(created_on).strftime("%d-%b-%Y %H:%M:%S"))
      # expect(mf_metadata[:created_by]).to eq(project.metadata_model.created_by)
      # expect(mf_metadata[:data_users]).to eq(data_user_ro.uid + "," + data_user_rw.uid)
      expect(mf_metadata[:quota_allocation]).to eq("700 TB")
    end
  end

  describe "#xml_payload" do
    xit "creates the asset create payload" do
      project = FactoryBot.create :project, project_id: "abc-123", project_directory: "testasset"
      create_request = described_class.new(session_token: nil, project: project, namespace: nil)
      expected_xml = "<?xml version=\"1.0\"?>\n" \
      "<request xmlns:tigerdata=\"http://tigerdata.princeton.edu\">\n" \
      "  <service name=\"asset.create\">\n" \
      "    <args>\n" \
      "      <name>testasset</name>\n" \
      "      <meta>\n" \
      "        <tigerdata:project>\n" \
      "          <ProjectDirectory>#{project.project_directory}</ProjectDirectory>\n" \
      "          <Title>#{project.metadata[:title]}</Title>\n" \
      "          <Description>#{project.metadata[:description]}</Description>\n" \
      "          <DataSponsor>#{project.metadata[:data_sponsor]}</DataSponsor>\n" \
      "          <DataManager>#{project.metadata[:data_manager]}</DataManager>\n" \
      "          <Department>77777</Department>\n" \
      "          <Department>88888</Department>\n" \
      "          <DataUser>n/a</DataUser>\n" \
      "          <ProjectID>abc-123</ProjectID>\n" \
      "        </tigerdata:project>\n" \
      "      </meta>\n" \
      "      <quota>\n" \
       "        <allocation>500 GB</allocation>\n" \
       "        <description>Project Quota</description>\n" \
       "      </quota>\n" \
      "      <collection cascade-contained-asset-index=\"true\" contained-asset-index=\"true\" unique-name-index=\"true\">true</collection>\n" \
      "      <type>application/arc-asset-collection</type>\n" \
      "    </args>\n" \
      "  </service>\n" \
      "</request>\n"
      expect(create_request.xml_payload).to eq(expected_xml)
    end
  end

  describe "#xtoshell_xml" do
    xit "creates the asset create xml in a format that can be passed to xtoshell in aterm" do
      project = FactoryBot.create :project, project_id: "abc-123", project_directory: "testasset"
      create_request = described_class.new(session_token: nil, project: project, namespace: nil)
      expected_xml = "<request xmlns:tigerdata='http://tigerdata.princeton.edu'><service name='asset.create'><name>testasset</name>" \
                     "<meta><tigerdata:project><ProjectDirectory>#{project.project_directory}</ProjectDirectory><Title>#{project.metadata[:title]}</Title>" \
                     "<Description>#{project.metadata[:description]}</Description>" \
                     "<DataSponsor>#{project.metadata[:data_sponsor]}</DataSponsor><DataManager>#{project.metadata[:data_manager]}</DataManager>" \
                     "<Department>77777</Department><Department>88888</Department><DataUser>n/a</DataUser>" \
                     "<ProjectID>abc-123</ProjectID></tigerdata:project></meta>" \
                     "<quota><allocation>500 GB</allocation><description>Project Quota</description></quota>" \
                     "<collection cascade-contained-asset-index='true' contained-asset-index='true' unique-name-index='true'>true</collection>" \
                     "<type>application/arc-asset-collection</type></service></request>"
      expect(create_request.xtoshell_xml).to eq(expected_xml)
    end
  end
end
