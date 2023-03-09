# frozen_string_literal: true

RSpec.shared_context "when connecting to the Mediaflux server API" do
  let(:session_token) { "test-session-token" }
  let(:logon_response_body) do
    <<-XML
<?xml version="1.0" encoding="UTF-8" ?>
<response>
  <reply type="result">
    <result>
      <session id="4458" timeout="1800" wallet="true">#{session_token}</session>
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
  let(:asset1_metadata) do
    {
      path: "/asset1",
      type: "collection",
      collection: true
    }
  end
  let(:asset2_metadata) do
    {
      path: "/asset2",
      type: "namespace",
      collection: false
    }
  end
  let(:asset3_metadata) do
    {
      path: "/asset3",
      type: "collection",
      collection: true
    }
  end
  let(:asset_ids) do
    [
      1, 2, 3
    ]
  end
  let(:query_results) do
    {
      ids: asset_ids,
      cursor: {
        from: 1,
        to: 2,
        prev: 1,
        next: 2
      }
    }
  end
  let(:mf) { instance_double(MediaFluxClient) }
end

RSpec.configure do |config|
  config.include_context "when connecting to the Mediaflux server API"

  config.before(:each) do |ex|
    if ex.metadata[:stub_mediaflux]
      allow(MediaFluxClient).to receive(:new).and_return(mf)
      allow(mf).to receive(:get_metadata).and_return(asset1_metadata, asset2_metadata, asset3_metadata)
      allow(mf).to receive(:query).and_return(query_results)
      allow(mf).to receive(:version).and_return({ version: "test-version" })
    end
  end
end
