# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::TokenCreateRequest, type: :model do
  subject(:request) { described_class.new(session_token: session_token, domain: "example", user: "atest") }

  let(:session_token) { "test-session-token" }
  let(:identity_token) { "test-identity-token" }
  let(:response_body) do
    <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <reply type="result">
    <result>
      <token id="2" actor-type="identity" actor-name="24">#{identity_token}</token>
    </result>
  </reply>
</response>
    XML
  end

  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  before do
    stub_request(:post, mediflux_url).to_return(status: 200, body: response_body)
  end

  describe "#identity" do
    it "creates an identity token for the user" do
      expect(request.identity).to eq(identity_token)

      assert_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
                       body: /<grant-user-roles>true<\/grant-user-roles>.*<domain>example<\/domain>.*<user>atest<\/user>/m)
    end
  end
end
