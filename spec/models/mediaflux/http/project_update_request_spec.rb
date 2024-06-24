# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::ProjectUpdateRequest, type: :model do
  let(:mediaflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }
  let(:metadata) do
    {
      project_directory: "code",
      title: "title",
      description: "description",
      data_sponsor: "data_sponsor",
      data_manager: "data_manager",
      updated_by: "abc123",
      updated_on: "now",
      departments: ["RDSS", "HPC"]
    }
  end

  let(:update_request) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_update_request.xml")
    File.new(filename).read
  end

  let(:update_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_update_response.xml")
    File.new(filename).read
  end

  describe "metadata values" do
    before do
      stub_request(:post, mediaflux_url)
        .with(body: update_request)
        .to_return(status: 200, body: update_response, headers: {})
    end

    it "passes the metadata values in the request" do
      FactoryBot.create :user, uid: "dm1"
      FactoryBot.create :user, uid: "ds1"
      project = FactoryBot.create :project, mediaflux_id: '1234', updated_on: Time.parse("18-JUN-2024 20:32:37 UTC"), created_on: Time.parse("17-JUN-2024 20:32:37 UTC"),
                                            created_by: "uid1", updated_by: "uid2", title: "Danger Cat", data_manager: "dm1", data_sponsor: "ds1"
      update_request = described_class.new(session_token: "secretsecret/2/31", project: project)
      update_request.resolve
      expect(WebMock).to have_requested(:post, mediaflux_url)
    end

    context "an asset with metadata" do
      it "sends the metadata to the server", connect_to_mediaflux: true do
        data_user_ro = FactoryBot.create :user
        data_user_rw = FactoryBot.create :user
        session_id = data_user_ro.mediaflux_session
        updated_on = Time.current.in_time_zone("America/New_York").iso8601
        created_on = Time.current.in_time_zone("America/New_York").advance(days: -1).iso8601
        project = FactoryBot.create :project, data_user_read_only: [data_user_ro.uid], data_user_read_write: [data_user_rw.uid], created_on: created_on, 
                                                project_id: "abc/123", project_directory: "testasset"
        create_request = Mediaflux::Http::ProjectCreateRequest.new(session_token: session_id, project:, namespace: Rails.configuration.mediaflux[:api_root_ns])
        expect(create_request.response_error).to be_blank
        expect(create_request.id).not_to be_blank

        project.mediaflux_id = create_request.id
        project.metadata_json[:title] = "New Title"
        project.metadata_json[:updated_by] = data_user_rw.uid
        project.metadata_json[:updated_on] = updated_on
        update_request = described_class.new(session_token: session_id, project: project)
        update_request.resolve
        expect(update_request.response_error).to be_blank
        req = Mediaflux::Http::AssetMetadataRequest.new(session_token: session_id, id: project.mediaflux_id)
        metadata  = req.metadata
        
        expect(metadata[:name]).to eq("testasset")
        expect(metadata[:title]).to eq("New Title")
        expect(metadata[:description]).to eq(project.metadata[:description])
        expect(metadata[:data_sponsor]).to eq(project.metadata[:data_sponsor])
        expect(metadata[:departments]).to eq(project.metadata[:departments])
        # TODO Should really utilize MediafluxTime, but the time class upcases the date and does not zero pad the day
        expect(metadata[:created_on]).to eq(Time.zone.parse(created_on).strftime("%d-%b-%Y %H:%M:%S"))
        expect(metadata[:created_by]).to eq(project.metadata[:created_by])
        expect(metadata[:updated_on]).to eq(Time.zone.parse(updated_on).strftime("%d-%b-%Y %H:%M:%S"))
        expect(metadata[:updated_by]).to eq(project.metadata[:updated_by])
        expect(metadata[:ro_users]).to eq([data_user_ro.uid])
        expect(metadata[:rw_users]).to eq([data_user_rw.uid])
        end
    end

  end

  describe "#xml_payload" do
  it "creates the asset update payload" do
    FactoryBot.create :user, uid: "dm1"
    FactoryBot.create :user, uid: "ds1"
    project = FactoryBot.create :project, mediaflux_id: '1234', updated_on: Time.parse("18-JUN-2024 20:32:37 UTC"), created_on: Time.parse("17-JUN-2024 20:32:37 UTC"),
                                          created_by: "uid1", updated_by: "uid2", title: "Danger Cat", data_manager: "dm1", data_sponsor: "ds1"
    update_request = described_class.new(session_token: nil, project:)
    expected_xml = "<?xml version=\"1.0\"?>\n" \
    "<request xmlns:tigerdata=\"http://tigerdata.princeton.edu\">\n" \
    "  <service name=\"asset.set\">\n" \
    "    <args>\n" \
    "      <id>1234</id>\n" \
    "      <meta>\n" \
    "        <tigerdata:project>\n" \
    "          <ProjectDirectory>#{project.project_directory}</ProjectDirectory>\n" \
    "          <Title>#{project.metadata[:title]}</Title>\n" \
    "          <Description>#{project.metadata[:description]}</Description>\n" \
    "          <Status>pending</Status>\n" \
    "          <SchemaVersion>0.6.1</SchemaVersion>\n" \
    "          <DataSponsor>#{project.metadata[:data_sponsor]}</DataSponsor>\n" \
    "          <DataManager>#{project.metadata[:data_manager]}</DataManager>\n" \
    "          <Department>RDSS</Department>\n" \
    "          <Department>PRDS</Department>\n" \
    "          <CreatedBy>uid1</CreatedBy>\n" \
    "          <CreatedOn>17-JUN-2024 20:32:37</CreatedOn>\n" \
    "          <UpdatedBy>#{project.metadata[:updated_by]}</UpdatedBy>\n" \
    "          <UpdatedOn>#{MediafluxTime.format_date_for_mediaflux(project.metadata[:updated_on])}</UpdatedOn>\n" \
    "          <ProjectID/>\n" \
    "          <StorageCapacity>\n" \
    "            <Size>500</Size>\n" \
    "            <Unit>GB</Unit>\n" \
    "          </StorageCapacity>\n" \
    "          <Performance Requested=\"standard\">standard</Performance>\n" \
    "          <Submission>\n" \
    "            <RequestedBy>uid1</RequestedBy>\n" \
    "            <RequestDateTime>17-JUN-2024 20:32:37</RequestDateTime>\n" \
    "          </Submission>\n" \
    "          <ProjectPurpose>research</ProjectPurpose>\n" \
    "        </tigerdata:project>\n" \
    "      </meta>\n" \
    "    </args>\n" \
    "  </service>\n" \
    "</request>\n"
    expect(update_request.xml_payload).to eq(expected_xml)
  end
end
end
