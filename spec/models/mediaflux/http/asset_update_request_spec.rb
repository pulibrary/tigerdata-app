# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::AssetUpdateRequest, type: :model do
  let(:mediaflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }
  let(:metadata) do
    {
      code: "code",
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
      update_request = described_class.new(session_token: "secretsecret/2/31", id: "1234", tigerdata_values: metadata)
      update_request.resolve
      expect(WebMock).to have_requested(:post, mediaflux_url)
    end

    context "an asset with metadata" do
      before do
        stub_request(:post, mediaflux_url).to_return(status: 200, body: update_response, headers: {})
      end
      it "sends the metadata to the server" do
        data_user_ro = FactoryBot.create :user
        data_user_rw = FactoryBot.create :user
        updated_on = Time.current.in_time_zone("America/New_York").iso8601
        project = FactoryBot.create :project, data_user_read_only: [data_user_ro.uid], data_user_read_write: [data_user_rw.uid], updated_on: updated_on
        tigerdata_values = ProjectMediaflux.project_values(project:)
        update_request = described_class.new(session_token: "secretsecret/2/31", id: "1234", tigerdata_values: tigerdata_values)
        update_request.resolve
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<Title>#{project.metadata[:title]}</Title>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<Description>#{project.metadata[:description]}</Description>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<DataSponsor>#{project.metadata[:data_sponsor]}</DataSponsor>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<DataManager>#{project.metadata[:data_manager]}</DataManager>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<Department>#{project.metadata[:departments].first}</Department>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<Department>#{project.metadata[:departments].last}</Department>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<UpdatedOn>#{ProjectMediaflux.format_date_for_mediaflux(project.metadata[:updated_on])}</UpdatedOn>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<UpdatedBy>#{project.metadata[:updated_by]}</UpdatedBy>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<DataUser ReadOnly=\"true\">#{data_user_ro.uid}</DataUser>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<DataUser>#{data_user_rw.uid}</DataUser>") }).to have_been_made
      end
    end

  end

  describe "#xml_payload" do
  it "creates the asset update payload" do
    project = FactoryBot.create :project
    tigerdata_values = ProjectMediaflux.project_values(project:)
    update_request = described_class.new(session_token: nil, id: '1234', tigerdata_values: tigerdata_values)
    expected_xml = "<?xml version=\"1.0\"?>\n" \
    "<request xmlns:tigerdata=\"http://tigerdata.princeton.edu\">\n" \
    "  <service name=\"asset.set\">\n" \
    "    <args>\n" \
    "      <id>1234</id>\n" \
    "      <meta>\n" \
    "        <tigerdata:project>\n" \
    "          <Code>#{project.directory}</Code>\n" \
    "          <Title>#{project.metadata[:title]}</Title>\n" \
    "          <Description>#{project.metadata[:description]}</Description>\n" \
    "          <DataSponsor>#{project.metadata[:data_sponsor]}</DataSponsor>\n" \
    "          <DataManager>#{project.metadata[:data_manager]}</DataManager>\n" \
    "          <UpdatedBy>#{project.metadata[:updated_by]}</UpdatedBy>\n" \
    "          <UpdatedOn>#{ProjectMediaflux.format_date_for_mediaflux(project.metadata[:updated_on])}</UpdatedOn>\n" \
    "          <Department>RDSS</Department>\n" \
    "          <Department>PRDS</Department>\n" \
    "        </tigerdata:project>\n" \
    "      </meta>\n" \
    "    </args>\n" \
    "  </service>\n" \
    "</request>\n"
    expect(update_request.xml_payload).to eq(expected_xml)
  end
end
end
