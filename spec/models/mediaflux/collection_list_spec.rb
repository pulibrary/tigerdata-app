# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::CollectionList, type: :model do

  let(:login_response) do
    filename = Rails.root.join("spec", "fixtures", "login_response.xml")
    File.new(filename).read
  end
  let(:collection_response) do
    filename = Rails.root.join("spec", "fixtures", "collection_list_response.xml")
    File.new(filename).read
  end

  describe "#initialize" do
    before do
      stub_request(:post, "http://test.mediaflux.com:8888/__mflux_svc__").
         with( body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"system.logon\">\n    <args>\n      <domain>system</domain>\n      <user>manager</user>\n      <password>change_me</password>\n    </args>\n  </service>\n</request>\n").
         to_return(status: 200, body: login_response, headers: {})
      stub_request(:post, "http://test.mediaflux.com:8888/__mflux_svc__").
         with( body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.collection.list\" session=\"secretsecret/2/31\"/>\n</request>\n").
         to_return(status: 200, body: collection_response, headers: {})
    end
    it "logs the user in" do
      list = described_class.new()
      expect(list.collections.count).to eq(1) # root collection /
      expect(list.collections.children.count).to eq(13) # sub collections
      expect(WebMock).to have_requested(:post, "http://test.mediaflux.com:8888/__mflux_svc__").twice
    end
  end
end
