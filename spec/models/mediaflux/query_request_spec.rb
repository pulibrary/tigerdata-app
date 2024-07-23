# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::QueryRequest, type: :model do
  let(:mediaflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }
  let(:query_response) { fixture_file("files/query_response.xml") }

  describe "#result" do
    before do
      stub_request(:post, mediaflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query\" session=\"secretsecret/2/31\">\n    <args>\n      "\
        "<where>asset in collection 123</where>\n      <action>get-values</action>\n      <xpath ename=\"name\">name</xpath>\n      "\
        "<xpath ename=\"path\">path</xpath>\n      <xpath ename=\"total-size\">content/@total-size</xpath>\n      "\
        "<xpath ename=\"mtime\">mtime</xpath>\n      <xpath ename=\"collection\">@collection</xpath>\n      "\
        "<as>iterator</as>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: query_response, headers: {})
    end

    it "returns an iterator" do
      query_request = described_class.new(session_token: "secretsecret/2/31", collection: "123")
      result = query_request.result
      expect(result).to eq(246)
      expect(WebMock).to have_requested(:post, mediaflux_url)
    end
  end

  context "deep search" do
    before do
      stub_request(:post, mediaflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query\" session=\"secretsecret/2/31\">\n    <args>\n      "\
        "<where>asset in static collection or subcollection of 123</where>\n      <action>get-values</action>\n      "\
        "<xpath ename=\"name\">name</xpath>\n      <xpath ename=\"path\">path</xpath>\n      <xpath ename=\"total-size\">content/@total-size</xpath>\n      "\
        "<xpath ename=\"mtime\">mtime</xpath>\n      <xpath ename=\"collection\">@collection</xpath>\n      "\
        "<as>iterator</as>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: query_response, headers: {})
    end

    it "honors the deep search parameter" do
      query_request = described_class.new(session_token: "secretsecret/2/31", collection: "123", deep_search: true)
      result = query_request.result
      expect(result).to eq(246)
      expect(WebMock).to have_requested(:post, mediaflux_url)
    end
  end

  context "action get-name" do
    before do
      stub_request(:post, mediaflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query\" session=\"secretsecret/2/31\">\n    <args>\n      "\
        "<where>asset in collection 123</where>\n      <action>get-name</action>\n      <as>iterator</as>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: query_response, headers: {})
    end

    it "honors the get-name action" do
      query_request = described_class.new(session_token: "secretsecret/2/31", collection: "123", action: "get-name")
      result = query_request.result
      expect(result).to eq(246)
      expect(WebMock).to have_requested(:post, mediaflux_url)
    end
  end

  context "action get-values" do
    before do
      # Notice the :xpath parameters after the get-action in the request
      stub_request(:post, mediaflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query\" session=\"secretsecret/2/31\">\n    <args>\n      "\
        "<where>asset in collection 123</where>\n      <action>get-values</action>\n      "\
        "<xpath ename=\"name\">name</xpath>\n      <xpath ename=\"path\">path</xpath>\n      <xpath ename=\"total-size\">content/@total-size</xpath>\n      "\
        "<xpath ename=\"mtime\">mtime</xpath>\n      <xpath ename=\"collection\">@collection</xpath>\n      <as>iterator</as>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: query_response, headers: {})
    end

    it "request the custom fields when using get-values" do
      query_request = described_class.new(session_token: "secretsecret/2/31", collection: "123", action: "get-values")
      result = query_request.result
      expect(result).to eq(246)
      expect(WebMock).to have_requested(:post, mediaflux_url)
    end
  end
end
