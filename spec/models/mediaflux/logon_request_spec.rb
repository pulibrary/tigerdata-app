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

  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  before do
    stub_request(:post, mediflux_url).to_return(status: 200, body: response_body)
  end

  describe "#session_token" do
    it "authenticates and stores the session token" do
      expect(request.session_token).to eq(session_token)
      assert_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
                       body: /<domain>system<\/domain>.*<user>manager<\/user>.*<password>change_me<\/password>/m)
      assert_not_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
                       body: /<token>/)
    end

    context "with a different domain" do
      subject(:request) { described_class.new domain: "princeton" }
      it "authenticates and stores the session token" do
        expect(request.session_token).to eq(session_token)
        assert_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
                         body: /<domain>princeton<\/domain>/)
      end
    end

    context "with a different username" do
      subject(:request) { described_class.new user: "atest" }
      it "authenticates and stores the session token" do
        expect(request.session_token).to eq(session_token)
        assert_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
                         body: /<user>atest<\/user>/)
      end
    end

    context "with a different password" do
      subject(:request) { described_class.new password: "password" }
      it "authenticates and stores the session token" do
        expect(request.session_token).to eq(session_token)
        assert_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
                         body: /<password>password<\/password>/)
      end
    end

    context "with a token" do
      subject(:request) { described_class.new identity_token: "tokentoken" }

      it "authenticates and stores the session token" do
        expect(request.session_token).to eq(session_token)
        assert_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
                          body: /<token>tokentoken/)
        assert_not_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
                          body: /<user>/)
      end
    end
  end
  describe "#resolve", connect_to_mediaflux: true do
    it "returns the net response" do
      response = request.resolve
      expect(response).to be_instance_of(Net::HTTPOK)
    end
  end
end
