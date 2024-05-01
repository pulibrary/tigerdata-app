# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::AssetCreateRequest, type: :model do
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
      it "sends the metadata to the server" do
        data_user_ro = FactoryBot.create :user
        data_user_rw = FactoryBot.create :user
        created_on = Time.current.in_time_zone("America/New_York").iso8601
        project = FactoryBot.create :project, data_user_read_only: [data_user_ro.uid], data_user_read_write: [data_user_rw.uid], created_on: created_on
        tigerdata_values = ProjectMediaflux.project_values(project:)
        create_request = described_class.new(session_token: "secretsecret/2/31", name: "testasset", collection: false, tigerdata_values: tigerdata_values)
        expect(create_request.id).to eq("1068")
        puts "created on #{project.metadata[:created_on]}"
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<name>testasset</name>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<Title>#{project.metadata[:title]}</Title>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<Description>#{project.metadata[:description]}</Description>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<DataSponsor>#{project.metadata[:data_sponsor]}</DataSponsor>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<DataManager>#{project.metadata[:data_manager]}</DataManager>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<Department>#{project.metadata[:departments].first}</Department>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<Department>#{project.metadata[:departments].last}</Department>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<CreatedOn>#{ProjectMediaflux.format_date_for_mediaflux(created_on)}</CreatedOn>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<CreatedBy>#{project.metadata[:created_by]}</CreatedBy>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<DataUser ReadOnly=\"true\">#{data_user_ro.uid}</DataUser>") }).to have_been_made
        expect(a_request(:post, mediflux_url).with { |req| req.body.include?("<DataUser>#{data_user_rw.uid}</DataUser>") }).to have_been_made
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
      "          <ProjectDirectory>#{project.directory}</ProjectDirectory>\n" \
      "          <Title>#{project.metadata[:title]}</Title>\n" \
      "          <Description>#{project.metadata[:description]}</Description>\n" \
      "          <Status>#{project.metadata[:status]}</Status>\n" \
      "          <DataSponsor>#{project.metadata[:data_sponsor]}</DataSponsor>\n" \
      "          <DataManager>#{project.metadata[:data_manager]}</DataManager>\n" \
      "          <Department>RDSS</Department>\n" \
      "          <Department>PRDS</Department>\n" \
      "          <CreatedOn>#{ProjectMediaflux.format_date_for_mediaflux(project.metadata[:created_on])}</CreatedOn>\n" \
      "          <CreatedBy>#{project.metadata[:created_by]}</CreatedBy>\n" \
      "          <ProjectID>abc-123</ProjectID>\n" \
      "          <StorageCapacity>\n" \
      "            <Size>500</Size>\n" \
      "            <Unit>GB</Unit>\n" \
      "          </StorageCapacity>\n" \
      "          <Performance Requested=\"standard\">standard</Performance>\n" \
      "          <Submission>\n" \
      "            <RequestedBy>#{project.metadata[:created_by]}</RequestedBy>\n" \
      "            <RequestDateTime>#{ProjectMediaflux.format_date_for_mediaflux(project.metadata[:created_on])}</RequestDateTime>\n" \
      "          </Submission>\n" \
      "          <ProjectPurpose>research</ProjectPurpose>\n" \
      "          <SchemaVersion>0.6.1</SchemaVersion>\n" \
      "        </tigerdata:project>\n" \
      "      </meta>\n" \
      "    </args>\n" \
      "  </service>\n" \
      "</request>\n"
      expect(create_request.xml_payload).to eq(expected_xml)
    end
  end

  describe "#xtoshell_xml" do
    it "creates the asset create xml in a format that can be passed to xtoshell in aterm" do
      project = FactoryBot.create :project, project_id: "abc-123"
      tigerdata_values = ProjectMediaflux.project_values(project:)
      create_request = described_class.new(session_token: nil, name: "testasset", collection: false, tigerdata_values: tigerdata_values)
      expected_xml = "<request xmlns:tigerdata='http://tigerdata.princeton.edu'><service name='asset.create'><name>testasset</name>" \
                     "<meta><tigerdata:project><ProjectDirectory>#{project.directory}</ProjectDirectory><Title>#{project.metadata[:title]}</Title>" \
                     "<Description>#{project.metadata[:description]}</Description><Status>#{project.metadata[:status]}</Status>" \
                     "<DataSponsor>#{project.metadata[:data_sponsor]}</DataSponsor><DataManager>#{project.metadata[:data_manager]}</DataManager>" \
                     "<Department>RDSS</Department><Department>PRDS</Department><CreatedOn>#{ProjectMediaflux.format_date_for_mediaflux(project.metadata[:created_on])}</CreatedOn>" \
                     "<CreatedBy>#{project.metadata[:created_by]}</CreatedBy><ProjectID>abc-123</ProjectID><StorageCapacity><Size>500</Size><Unit>GB</Unit></StorageCapacity>" \
                     "<Performance Requested='standard'>standard</Performance><Submission><RequestedBy>#{project.metadata[:created_by]}</RequestedBy>" \
                     "<RequestDateTime>#{ProjectMediaflux.format_date_for_mediaflux(project.metadata[:created_on])}</RequestDateTime></Submission>" \
                     "<ProjectPurpose>research</ProjectPurpose><SchemaVersion>0.6.1</SchemaVersion></tigerdata:project></meta></service></request>"
      expect(create_request.xtoshell_xml).to eq(expected_xml)
    end
  end
end
