# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ServiceExecuteRequest, connect_to_mediaflux: true, type: :model, integration: true do
  let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  subject(:request) { described_class.new(session_token: user.mediaflux_session, service_name: "asset.namespace.list") }
  let(:approved_project) { create_project_in_mediaflux(current_user: user) }
  let(:session_token) { "test-session-token" }
  let(:identity_token) { "test-identity-token" }
  let(:mediaflux_url) { Mediaflux::Request.uri.to_s }

  describe "#resolve" do
    it "sends the service execute" do
      request.resolve
      assert_requested(:post, mediaflux_url,
                       body: /service name="service.execute".*<service name="asset.namespace.list"\/>.*/m)
    end

    context "when a document is passed" do
      subject(:request) { described_class.new(session_token: session_token, service_name: "asset.namespace.list", document: "<id>1</id>") }

      it "sends the service execute" do
        request.resolve
        assert_requested(:post, mediaflux_url,
                         body: /service name="service.execute".*<service name="asset.namespace.list">.*<id>1<\/id>.*<\/service>.*/m)
      end
    end

    context "when a token is passed" do
      subject(:request) { described_class.new(session_token: session_token, service_name: "asset.namespace.list", token: "tokentoken") }

      it "sends the service execute" do
        request.resolve
        assert_requested(:post, mediaflux_url,
                         body: /service name="service.execute".*<token>tokentoken<\/token>.*<service name="asset.namespace.list"\/>.*/m)
      end
    end
  end
end
