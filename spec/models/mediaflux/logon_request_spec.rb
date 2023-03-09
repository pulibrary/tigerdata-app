# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::LogonRequest, type: :model do
  subject(:request) { described_class.new }

  let(:session_token) { "test-session-token" }
  let(:response_body) do
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

  before do
    WebMock.enable!

    stub_request(:post, "http://0.0.0.0:8888/__mflux_svc__").to_return(status: 200, body: response_body)
  end

  after do
    WebMock.disable!
  end

  describe "#resolve" do
    it "authenticates and stores the session token" do
      request.resolve

      expect(request.session_token).to eq(session_token)
    end
  end
end
