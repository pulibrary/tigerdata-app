# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::UpdateAssetRequest, type: :model do
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
        updated_on = DateTime.now
        project = FactoryBot.create :project, data_user_read_only: [data_user_ro.uid], data_user_read_write: [data_user_rw.uid], updated_on: updated_on
        tigerdata_values = ProjectMediaflux.project_values(project:)
        update_request = described_class.new(session_token: "secretsecret/2/31", id: "1234", tigerdata_values: tigerdata_values)
        update_request.resolve
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<title>#{project.metadata[:title]}</title>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<description>#{project.metadata[:description]}</description>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<data_sponsor>#{project.metadata[:data_sponsor]}</data_sponsor>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<data_manager>#{project.metadata[:data_manager]}</data_manager>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<departments>#{project.metadata[:departments].first}</departments>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<departments>#{project.metadata[:departments].last}</departments>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<updated_on>#{updated_on.strftime("%d-%b-%Y %H:%M:%S")}</updated_on>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<updated_by>#{project.metadata[:updated_by]}</updated_by>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<data_users_ro>#{data_user_ro.uid}</data_users_ro>") }).to have_been_made
        expect(a_request(:post, mediaflux_url).with { |req| req.body.include?("<data_users_rw>#{data_user_rw.uid}</data_users_rw>") }).to have_been_made
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
    "          <code>#{project.directory}</code>\n" \
    "          <title>#{project.metadata[:title]}</title>\n" \
    "          <description>#{project.metadata[:description]}</description>\n" \
    "          <data_sponsor>#{project.metadata[:data_sponsor]}</data_sponsor>\n" \
    "          <data_manager>#{project.metadata[:data_manager]}</data_manager>\n" \
    "          <updated_by>#{project.metadata[:updated_by]}</updated_by>\n" \
    "          <updated_on>#{project.metadata[:updated_on]}</updated_on>\n" \
    "          <departments>RDSS</departments>\n" \
    "          <departments>PRDS</departments>\n" \
    "        </tigerdata:project>\n" \
    "      </meta>\n" \
    "    </args>\n" \
    "  </service>\n" \
    "</request>\n"
    expect(update_request.xml_payload).to eq(expected_xml)
  end
end
end
