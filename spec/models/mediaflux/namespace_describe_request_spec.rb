# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceDescribeRequest, connect_to_mediaflux: true, type: :model do
  let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }
  let(:user) { FactoryBot.create(:user) }
  let(:approved_project) { FactoryBot.create(:approved_project) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n" }

  describe "#metadata" do
    before do
      approved_project.mediaflux_id = nil
      mediaflux_id = ProjectMediaflux.create!(project: approved_project, session_id: user.mediaflux_session)
      Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: mediaflux_id).resolve
    end
    it "parses a metadata response" do
      namespace_request = described_class.new(session_token: user.mediaflux_session, id: 34732)
      metadata = namespace_request.metadata
      expect(metadata[:id]).to eq("34732")
      expect(metadata[:path]).to eq("/td-test-001")
      expect(metadata[:name]).to eq("td-test-001")
      expect(metadata[:store]).to eq("data")
    end

    it "parses a metadata response with an namespace instead of an id" do
      namespace_request = described_class.new(session_token: user.mediaflux_session, path: "/td-test-001")
      metadata = namespace_request.metadata
      expect(metadata[:id]).to eq("34732")
      expect(metadata[:path]).to eq("/td-test-001")
      expect(metadata[:name]).to eq("td-test-001")
      expect(metadata[:store]).to eq("data")
    end
  end
end
