# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::AssetCreateRequest, connect_to_mediaflux: true, type: :model do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:session_token) { Mediaflux::LogonRequest.new.session_token }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:random_directory) { random_project_directory }
  let(:project) { create_project_in_mediaflux(current_user: user) }

  let(:create_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_create_response.xml")
    File.new(filename).read
  end

  describe "#id" do
    it "creates a collection on the server", :integration do
      create_request = described_class.new(session_token: session_token, name: random_directory, pid: project.mediaflux_id)
      expect(create_request.response_error).to be_blank
      expect(create_request.id).not_to be_blank
      req = Mediaflux::AssetMetadataRequest.new(session_token: session_token, id: create_request.id)
      metadata = req.metadata
      expect(metadata[:name]).to eq(random_directory)
    end
  end

  describe "#xml_payload" do
    it "creates the asset create payload", :integration do
      create_request = described_class.new(session_token: nil, name: random_directory, pid: project.mediaflux_id)
      expected_xml = "<?xml version=\"1.0\"?>\n" \
      "<request>\n" \
      "  <service name=\"asset.create\">\n" \
      "    <args>\n" \
      "      <name>#{random_directory}</name>\n" \
      "      <collection cascade-contained-asset-index=\"true\" contained-asset-index=\"true\" unique-name-index=\"true\">true</collection>\n" \
      "      <type>application/arc-asset-collection</type>\n" \
      "      <pid>#{project.mediaflux_id}</pid>\n" \
      "    </args>\n" \
      "  </service>\n" \
      "</request>\n"
      expect(create_request.xml_payload).to eq(expected_xml)
    end
  end

  describe "#xtoshell_xml" do
    it "creates the asset create xml in a format that can be passed to xtoshell in aterm", :integration do
      create_request = described_class.new(session_token: nil, name: random_directory, pid: project.mediaflux_id)
      expected_xml = "<request><service name='asset.create'><name>#{random_directory}</name>" \
                     "<collection cascade-contained-asset-index='true' contained-asset-index='true' unique-name-index='true'>true</collection>" \
                     "<type>application/arc-asset-collection</type><pid>#{project.mediaflux_id}</pid></service></request>"
      expect(create_request.xtoshell_xml).to eq(expected_xml)
    end
  end
end
