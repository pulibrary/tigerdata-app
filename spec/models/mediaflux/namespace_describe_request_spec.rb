# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceDescribeRequest, connect_to_mediaflux: true, type: :model do
  let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n" }

  describe "#metadata" do
    before do
      namespace_list_req = Mediaflux::NamespaceListRequest.new(session_token: user.mediaflux_session, parent_namespace: "/td-test-001")
      namespace_response = namespace_list_req.response_body.split("<namespace id=")[1]
      @namespace_id = namespace_response.split("leaf")[0].parameterize
    end
    it "parses a metadata response" do
      namespace_request = described_class.new(session_token: user.mediaflux_session, id: @namespace_id)
      metadata = namespace_request.metadata
      expect(metadata[:id]).to eq(@namespace_id)
      expect(metadata[:path]).to eq("/td-test-001/test")
      expect(metadata[:name]).to eq("test")
      expect(metadata[:description]).to eq("")
      expect(metadata[:store]).to eq("data")
    end

    it "parses a metadata response with an path instead of an id" do
      namespace_request = described_class.new(session_token: user.mediaflux_session, path: "/td-test-001/test")
      metadata = namespace_request.metadata
      expect(metadata[:id]).to eq(@namespace_id)
      expect(metadata[:path]).to eq("/td-test-001/test")
      expect(metadata[:name]).to eq("test")
      expect(metadata[:description]).to eq("")
      expect(metadata[:store]).to eq("data")
    end
  end
end
