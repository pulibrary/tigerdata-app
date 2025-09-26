# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ProjectUpdateRequest, connect_to_mediaflux: true, type: :model do
  let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }
  let(:session_token) { SystemUser.mediaflux_session }
  let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:approved_project) { create_project_in_mediaflux(current_user: user) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n" }

  describe "metadata values" do

    it "passes the metadata values in the request" ,
    :integration do
      update_request = described_class.new(session_token: session_token, project: approved_project)
      update_request.resolve
      expect(update_request.error?).to be false
      expect(update_request.response_body).to include(mediaflux_response)
    end

    context "an asset with metadata" do
      # TODO: We don't support yet updates to Mediaflux from the UI after the project has been created in Mediaflux
      # See https://github.com/pulibrary/tigerdata-app/issues/1608
      xit "sends the metadata to the server", connect_to_mediaflux: true do
        data_user_ro = FactoryBot.create :user
        data_user_rw = FactoryBot.create :user
        session_id = session_token
        updated_on = Time.current.in_time_zone("America/New_York").iso8601.to_s
        created_on = Time.current.in_time_zone("America/New_York").advance(days: -1).iso8601.to_s
        project = FactoryBot.create :project, data_user_read_only: [data_user_ro.uid], data_user_read_write: [data_user_rw.uid], created_on: created_on,
                                                project_id: "abc/123", project_directory: "testasset"
        create_request = Mediaflux::ProjectCreateRequest.new(session_token: session_id, project:, namespace: Rails.configuration.mediaflux[:api_root_ns])
        expect(create_request.response_error).to be_blank
        expect(create_request.id).not_to be_blank

        project.mediaflux_id = create_request.id
        project.metadata_model.title = "New Title"
        project.metadata_model.updated_by = data_user_rw.uid
        project.metadata_model.updated_on = updated_on
        update_request = described_class.new(session_token: session_id, project: project)
        update_request.resolve
        expect(update_request.response_error).to be_blank
        req = Mediaflux::AssetMetadataRequest.new(session_token: session_id, id: project.mediaflux_id)
        mf_metadata  = req.metadata

        expect(mf_metadata[:name]).to eq("testasset")
        expect(mf_metadata[:title]).to eq("New Title")
        expect(mf_metadata[:description]).to eq(project.metadata_model.description)
        expect(mf_metadata[:data_sponsor]).to eq(project.metadata_model.data_sponsor)
        expect(mf_metadata[:departments]).to eq(project.metadata_model.departments)
        # TODO Should really utilize Mediaflux::Time, but the time class upcases the date and does not zero pad the day
        # expect(mf_metadata[:created_on]).to eq(Time.zone.parse(created_on).strftime("%d-%b-%Y %H:%M:%S"))
        # expect(mf_metadata[:created_by]).to eq(project.metadata_model.created_by)
        # expect(mf_metadata[:updated_on]).to eq(Time.zone.parse(updated_on).strftime("%d-%b-%Y %H:%M:%S"))
        # expect(mf_metadata[:updated_by]).to eq(project.metadata_model.updated_by)
        # Data Users
        expect(mf_metadata[:rw_users]).to eq([data_user_ro.uid + "," + data_user_rw.uid])
        end
    end

  end

  describe "#xml_payload" do
  it "creates the asset update payload" do
    FactoryBot.create :user, uid: "dm1"
    FactoryBot.create :user, uid: "ds1"
    project = FactoryBot.create :project, mediaflux_id: '1234', updated_on: Time.parse("18-JUN-2024 20:32:37 UTC").to_s, created_on: Time.parse("17-JUN-2024 20:32:37 UTC").to_s,
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
    "          <DataSponsor>#{project.metadata[:data_sponsor]}</DataSponsor>\n" \
    "          <DataManager>#{project.metadata[:data_manager]}</DataManager>\n" \
    "          <Department>77777</Department>\n" \
    "          <Department>88888</Department>\n" \
    "          <DataUser>n/a</DataUser>\n" \
    "        </tigerdata:project>\n" \
    "      </meta>\n" \
    "    </args>\n" \
    "  </service>\n" \
    "</request>\n"
    expect(update_request.xml_payload).to eq(expected_xml)
  end
end
end
