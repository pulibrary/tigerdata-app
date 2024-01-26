# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::CreateAssetRequest, type: :model do
  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:create_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_create_response.xml")
    File.new(filename).read
  end

  describe "#id" do
    before do
      stub_request(:post, mediflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.create\" session=\"secretsecret/2/31\">\n    "\
                    "<args>\n      <name>testasset</name>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: create_response, headers: {})
    end

    it "parses a metadata response" do
      create_request = described_class.new(session_token: "secretsecret/2/31", name: "testasset", collection: false)
      expect(create_request.id).to eq("1068")
      expect(a_request(:post, mediflux_url).with do |req| 
        req.body.include?("<name>testasset</name>")
      end
      ).to have_been_made
    end

    context "an asset with metadata" do
      before do
        stub_request(:post, mediflux_url).to_return(status: 200, body: create_response, headers: {})
      end
      it "send the metadata to the server" do
        data_user_ro = FactoryBot.create :user
        data_user_rw = FactoryBot.create :user
        created_on = DateTime.now
        project = FactoryBot.create :project, data_user_read_only: [data_user_ro.uid], data_user_read_write: [data_user_rw.uid], created_on: created_on
        tigerdata_values = ProjectMediaflux.project_values(project:)
        create_request = described_class.new(session_token: "secretsecret/2/31", name: "testasset", collection: false, tigerdata_values: tigerdata_values)
        expect(create_request.id).to eq("1068")
        puts "created on #{project.metadata[:created_on]}"
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<name>testasset</name>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<title>#{project.metadata[:title]}</title>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<description>#{project.metadata[:description]}</description>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<data_sponsor>#{project.metadata[:data_sponsor]}</data_sponsor>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<data_manager>#{project.metadata[:data_manager]}</data_manager>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<departments>#{project.metadata[:departments].first}</departments>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<departments>#{project.metadata[:departments].last}</departments>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<created_on>#{created_on.strftime("%d-%b-%Y %H:%M:%S")}</created_on>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<created_by>#{project.metadata[:created_by]}</created_by>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<data_users_ro>#{data_user_ro.uid}</data_users_ro>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<data_users_rw>#{data_user_rw.uid}</data_users_rw>") }).to have_been_made
      end
    end

    context "A collection" do
      before do
        stub_request(:post, mediflux_url)
          .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.create\" session=\"secretsecret/2/31\">\n    "\
                      "<args>\n      <name>testasset</name>\n      <collection cascade-contained-asset-index=\"true\" contained-asset-index=\"true\" unique-name-index=\"true\">true</collection>\n"\
                      "      <type>application/arc-asset-collection</type>\n    </args>\n  </service>\n</request>\n")
          .to_return(status: 200, body: create_response, headers: {})
      end

      it "parses a metadata response" do
        create_request = described_class.new(session_token: "secretsecret/2/31", name: "testasset", collection: true)
        expect(create_request.id).to eq("1068")
        expect(a_request(:post, mediflux_url).with do |req| 
            req.body.include?("<name>testasset</name>") && 
            req.body.include?("<type>application/arc-asset-collection</type>")
          end
        ).to have_been_made
      end
    end

    context "A collection within a collection" do
      before do
        stub_request(:post, mediflux_url)
          .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.create\" session=\"secretsecret/2/31\">\n    "\
                      "<args>\n      <name>testasset</name>\n      <collection cascade-contained-asset-index=\"true\" contained-asset-index=\"true\" unique-name-index=\"true\">true</collection>\n"\
                      "      <type>application/arc-asset-collection</type>\n      <pid>5678</pid>\n" \
                      "    </args>\n  </service>\n</request>\n")
          .to_return(status: 200, body: create_response, headers: {})
      end

      it "parses a metadata response" do
        create_request = described_class.new(session_token: "secretsecret/2/31", name: "testasset", collection: true, pid: "5678")
        expect(create_request.id).to eq("1068")
        expect(a_request(:post, mediflux_url).with do |req| 
            req.body.include?("<name>testasset</name>") && 
            req.body.include?("<type>application/arc-asset-collection</type>")
          end
        ).to have_been_made
      end
    end

  end

  describe "#xml_payload" do
    it "creates the asset create payload" do
      project = FactoryBot.create :project, project_id: "abc-123"
      tigerdata_values = ProjectMediaflux.project_values(project:)
      create_request = described_class.new(session_token: nil, name: "testasset", collection: false, tigerdata_values: tigerdata_values)
      expected_xml = "<?xml version=\"1.0\"?>\n" \
      "<request xmlns:tigerdata=\"http://tigerdata.princeton.edu\">\n" \
      "  <service name=\"asset.create\">\n" \
      "    <args>\n" \
      "      <name>testasset</name>\n" \
      "      <meta>\n" \
      "        <tigerdata:project>\n" \
      "          <code>#{project.directory}</code>\n" \
      "          <title>#{project.metadata[:title]}</title>\n" \
      "          <description>#{project.metadata[:description]}</description>\n" \
      "          <status>#{project.metadata[:status]}</status>\n" \
      "          <data_sponsor>#{project.metadata[:data_sponsor]}</data_sponsor>\n" \
      "          <data_manager>#{project.metadata[:data_manager]}</data_manager>\n" \
      "          <departments>RDSS</departments>\n" \
      "          <departments>PRDS</departments>\n" \
      "          <created_on>#{project.metadata[:created_on]}</created_on>\n" \
      "          <created_by>#{project.metadata[:created_by]}</created_by>\n" \
      "          <project_id>abc-123</project_id>\n" \
      "          <storage_capacity>500 GB</storage_capacity>\n" \
      "          <storage_performance>standard</storage_performance>\n" \
      "          <project_purpose>research</project_purpose>\n" \
      "        </tigerdata:project>\n" \
      "      </meta>\n" \
      "    </args>\n" \
      "  </service>\n" \
      "</request>\n"
      expect(create_request.xml_payload).to eq(expected_xml)
    end
  end
end
