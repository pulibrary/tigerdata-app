# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceDescribeRequest, connect_to_mediaflux: true, type: :model do
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }

  describe "#metadata" do
    before do
      namespace_list_req = Mediaflux::NamespaceListRequest.new(session_token: user.mediaflux_session, parent_namespace: "/princeton")
      xml_doc = Nokogiri::XML(namespace_list_req.response_body)
      @tigerdata_ns = xml_doc.xpath("/response/reply/result/namespace/namespace[contains(text(), 'tigerdataNS')]").first
    end
    it "parses a metadata response", :integration do
      namespace_request = described_class.new(session_token: user.mediaflux_session, id: @tigerdata_ns.attributes["id"].value)
      metadata = namespace_request.metadata
      expect(metadata[:id]).to eq(@tigerdata_ns.attributes["id"].value)
      expect(metadata[:path]).to eq("/princeton/tigerdataNS")
      expect(metadata[:name]).to eq("tigerdataNS")
      expect(metadata[:description]).to eq("")
      expect(metadata[:store]).to eq("dell-ps-1-par")
    end

    it "parses a metadata response with an path instead of an id", :integration do
      namespace_request = described_class.new(session_token: user.mediaflux_session, path: "/princeton/tigerdataNS")
      metadata = namespace_request.metadata
      expect(metadata[:id]).to eq(@tigerdata_ns.attributes["id"].value)
      expect(metadata[:path]).to eq("/princeton/tigerdataNS")
      expect(metadata[:name]).to eq("tigerdataNS")
      expect(metadata[:description]).to eq("")
      expect(metadata[:store]).to eq("dell-ps-1-par")
    end
  end
end
