# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ServiceExecuteRequest, connect_to_mediaflux: true, type: :model do
  subject(:request) { described_class.new(session_token: user.mediaflux_session, service_name: "asset.namespace.list") }

  let(:user) { FactoryBot.create(:user) }
  let(:approved_project) { FactoryBot.create(:approved_project) }
  let(:session_token) { "test-session-token" }
  let(:identity_token) { "test-identity-token" }
  let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }

  before do
    # create a real collection as an example of a service execution
    approved_project.mediaflux_id = nil
    @mediaflux_id = ProjectMediaflux.create!(project: approved_project, session_id: user.mediaflux_session)
  end

  describe "#resolve" do
    it "sends the service execute" do
      request.resolve
      assert_requested(:post, "http://0.0.0.0:8888/__mflux_svc__",
                       body: /service name="service.execute".*<service name="asset.namespace.list"\/>.*/m)
    end

    context "when a document is passed" do
      subject(:request) { described_class.new(session_token: session_token, service_name: "asset.namespace.list", document: "<id>1</id>") }

      it "sends the service execute" do
        request.resolve
        assert_requested(:post, "http://0.0.0.0:8888/__mflux_svc__",
                         body: /service name="service.execute".*<service name="asset.namespace.list">.*<id>1<\/id>.*<\/service>.*/m)
      end
    end

    context "when a token is passed" do
      subject(:request) { described_class.new(session_token: session_token, service_name: "asset.namespace.list", token: "tokentoken") }

      it "sends the service execute" do
        request.resolve
        assert_requested(:post, "http://0.0.0.0:8888/__mflux_svc__",
                         body: /service name="service.execute".*<token>tokentoken<\/token>.*<service name="asset.namespace.list"\/>.*/m)
      end
    end
  end
end
