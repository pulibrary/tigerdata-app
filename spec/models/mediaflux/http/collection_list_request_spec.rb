# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::CollectionListRequest, type: :model do
  subject(:request) { described_class.new(session_token: session_token) }

  let(:response_body) do
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

  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  before do
    stub_request(:post, mediflux_url).to_return(status: 200, body: response_body)
  end

  describe "#resolve" do
    it "retrieves the listing of collections within the default namespace" do
      response = request.resolve

      expect(response.body).not_to be_nil
    end
  end
end
