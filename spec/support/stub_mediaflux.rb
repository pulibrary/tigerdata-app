# frozen_string_literal: true

RSpec.shared_context "Mediaflux server API" do
  let(:session_token) { "test-session-token" }
  let(:logon_response_body) do
    <<-XML
<?xml version="1.0" encoding="UTF-8" ?>
<response>
  <reply type="result">
    <result>
      <session id="4458" timeout="1800" wallet="true">
        #{session_token}
      </session>
      <locale>en-US</locale>
      <network-wait-timeout>30</network-wait-timeout>
      <user username="tigerdataapp">
        <name>tigerdataapp</name>
      </user>
    </result>
  </reply>
</response>
    XML
  end
  let(:collection_list_response_body) do
    <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <reply type="result">
    <result>
      <collection type="namespace" path="/">
        <collection type="namespace" id="1071" leaf="false" acl="false" name="Princeton"/>
        <collection type="asset" id="999" leaf="true" acl="false" unique-name-index="false" name="collection_2"/>
        <collection type="asset" id="1000" leaf="true" acl="false" unique-name-index="false" name="collection_3"/>
        <collection type="namespace" id="4" leaf="false" acl="false" name="mflux">
          <restricted-visibility>true</restricted-visibility>
        </collection>
        <collection type="namespace" id="6" leaf="false" acl="false" name="system">
          <restricted-visibility>true</restricted-visibility>
        </collection>
        <collection type="namespace" id="8" leaf="false" acl="false" name="www">
          <restricted-visibility>true</restricted-visibility>
        </collection>
      </collection>
    </result>
  </reply>
</response>
    XML
  end
end

RSpec.configure do |config|
  config.include_context("Mediaflux server API")

  config.before(:each) do |ex|
    if ex.metadata[:stub_mediaflux]
      WebMock.enable!

      # Stubbing the asset.collection.list request
      stub_request(:post, "http://0.0.0.0:8888/__mflux_svc__").with(
        body: /<service namespace="tigerdata" name="asset.collection.list" session="test-session-token"\/>/
      ).to_return(status: 200, body: collection_list_response_body)

      # Stubbing the system.logon request
      stub_request(:post, "http://0.0.0.0:8888/__mflux_svc__").with(
        body: /<service name="system.logon">/
      ).to_return(status: 200, body: logon_response_body)
    end
  end

  config.before(:each) do |ex|
    if ex.metadata[:stub_mediaflux]
      WebMock.disable!
    end
  end
end
