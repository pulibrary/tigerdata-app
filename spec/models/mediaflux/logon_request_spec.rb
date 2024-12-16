# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::LogonRequest, connect_to_mediaflux: true, type: :model do
  subject(:request) { described_class.new }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:session_token) { user.mediaflux_session }
  let(:mediaflux_url) { Mediaflux::Request.uri.to_s }

  describe "#session_token" do
    it "authenticates and stores the session token" do
      expect(request.session_token).to_not be_blank

      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<service name=\"system.logon\"")
      end).to have_been_made.at_least_once

      assert_not_requested(:post, mediaflux_url,
                       body: /<token>/)
    end

    context "with a different domain" do
      subject(:request) { described_class.new domain: "princeton" }
      it "authenticates and stores the session token" do
        expect(request.session_token).to be_blank # no universal user/pass for staging
        assert_requested(:post, mediaflux_url,
                         body: /<domain>princeton<\/domain>/)
      end
    end

    context "with a different username" do
      subject(:request) { described_class.new user: "atest" }
      it "authenticates and stores the session token" do
        expect(request.session_token).to be_blank
        assert_requested(:post, mediaflux_url,
                         body: /<user>atest<\/user>/)
      end
    end

    context "with a different password" do
      subject(:request) { described_class.new password: "password" }
      it "authenticates and stores the session token" do
        expect(request.session_token).to be_blank
        assert_requested(:post, mediaflux_url,
                         body: /<password>password<\/password>/)
      end
    end

    context "with a token" do
      subject(:request) { described_class.new identity_token: "tokentoken" }

      it "authenticates and stores the session token" do
        expect(request.session_token).to be_blank
        assert_requested(:post, mediaflux_url,
                          body: /<token>tokentoken/)
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
