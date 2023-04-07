# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::QueryRequest, type: :model do
  before do
    WebMock.enable!
  end

  after do
    WebMock.disable!
  end

  let(:mediflux_url) { "http://test.mediaflux.com:443/__mflux_svc__" }

  let(:query_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "namespace_asset_query_response.xml")
    File.new(filename).read
  end

  describe "#result" do
    before do
      stub_request(:post, mediflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query\" session=\"secretsecret/2/31\">\n    "\
                    "<args>\n      <where>namespace='/tigerdata/td-demo-001'</where>\n      <idx>1</idx>\n      <size>10</size>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: query_response, headers: {})
    end

    it "returns a cursor" do
      query_request = described_class.new(session_token: "secretsecret/2/31", aql_query: "namespace='/tigerdata/td-demo-001'")
      result = query_request.result
      expect(result[:ids]).to eq(["1057", "1058", "1059", "1060", "1061", "1062", "1063", "1064", "1065", "1066"])
      expect(result[:size]).to eq(0)
      cursor = result[:cursor]
      expect(cursor[:count]).to eq(10)
      expect(cursor[:from]).to eq(11)
      expect(cursor[:to]).to eq(20)
      expect(cursor[:prev]).to eq(1)
      expect(cursor[:next]).to eq(21)
      expect(cursor[:total]).to eq(21)
      expect(cursor[:remaining]).to eq(1)

      expect(WebMock).to have_requested(:post, mediflux_url)
    end

    context "when a collection is given" do
      let(:query_response) do
        filename = Rails.root.join("spec", "fixtures", "files", "collection_query_response.xml")
        File.new(filename).read
      end

      before do
        stub_request(:post, mediflux_url)
          .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query\" session=\"secretsecret/2/31\">\n    "\
                      "<args>\n      <collection>1067</collection>\n      <idx>1</idx>\n      <size>10</size>\n    </args>\n  </service>\n</request>\n")
          .to_return(status: 200, body: query_response, headers: {})
      end

      it "returns a cursor" do
        query_request = described_class.new(session_token: "secretsecret/2/31", collection: 1067)
        result = query_request.result
        expect(result[:ids]).to eq(["1067"])
        expect(result[:size]).to eq(0)
        cursor = result[:cursor]
        expect(cursor[:count]).to eq(1)
        expect(cursor[:from]).to eq(1)
        expect(cursor[:to]).to eq(1)
        expect(cursor[:prev]).to eq(0)
        expect(cursor[:next]).to eq(2)
        expect(cursor[:total]).to eq(1)
        expect(cursor[:remaining]).to eq(0)

        expect(WebMock).to have_requested(:post, mediflux_url)
      end
    end
  end
end
