# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::ServiceExecuteRequest, type: :model do
  subject(:request) { described_class.new(session_token: session_token, service_name: "asset.namespace.list") }

  let(:session_token) { "test-session-token" }
  let(:identity_token) { "test-identity-token" }
  let(:response_body) do
    <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <reply type="result">
    <result>
      <uuid>4892</uuid>
      <reply service="asset.namespace.list">
        <response>
          <namespace path="/">
            <namespace id="1080" leaf="true" acl="false">Princeton</namespace>
            <namespace id="4" leaf="false" acl="false" restricted-visibility="true">mflux</namespace>
            <namespace id="6" leaf="false" acl="false" restricted-visibility="true">system</namespace>
            <namespace id="8" leaf="false" acl="false" restricted-visibility="true">www</namespace>
          </namespace>
        </response>
      </reply>
    </result>
  </reply>
</response>
    XML
  end

  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  before do
    stub_request(:post, mediflux_url).to_return(status: 200, body: response_body)
  end

  describe "#resolve" do
    it "sends the service execute" do
      request.resolve
      assert_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
                       body: /service name="service.execute".*<service name="asset.namespace.list"\/>.*/m)
    end

    context "when a document is passed" do
      subject(:request) { described_class.new(session_token: session_token, service_name: "asset.namespace.list", document: "<id>1</id>") }

      it "sends the service execute" do
        request.resolve
        assert_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
                         body: /service name="service.execute".*<service name="asset.namespace.list">.*<id>1<\/id>.*<\/service>.*/m)
      end
    end

    context "when a token is passed" do
      subject(:request) { described_class.new(session_token: session_token, service_name: "asset.namespace.list", token: "tokentoken") }

      it "sends the service execute" do
        request.resolve
        assert_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
                         body: /service name="service.execute".*<token>tokentoken<\/token>.*<service name="asset.namespace.list"\/>.*/m)
      end
    end
  end
end
