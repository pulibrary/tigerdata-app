# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::StoreListRequest, type: :model do
  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:store_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_store_list_response.xml")
    File.new(filename).read
  end

  describe "#metadata" do
    before do
      stub_request(:post, mediflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.store.list\" session=\"secretsecret/2/31\"/>\n</request>\n")
        .to_return(status: 200, body: store_response, headers: {})
    end
    it "parses a metadata response" do
      stores_request = described_class.new(session_token: "secretsecret/2/31")
      stores = stores_request.stores
      expect(stores.count).to eq(5)
      expect(stores.first).to eq({ id: "1", name: "db", tag: "", type: "database" })
      expect(WebMock).to have_requested(:post, mediflux_url)
    end
  end
end
