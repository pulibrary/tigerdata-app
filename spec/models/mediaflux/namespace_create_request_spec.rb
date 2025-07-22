# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceCreateRequest, connect_to_mediaflux: true, type: :model do
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<response><reply type=\"result\"><result></result></reply></response>" }
  let(:namespace_test) { "princeton/namespace-create-test/#{random_project_directory}NS"}

  describe "#resolve" do
    before do
      # delete the namespace if it exists
      destroy_request = Mediaflux::NamespaceDestroyRequest.new(session_token: user.mediaflux_session, namespace: namespace_test, ignore_missing: true)
      destroy_request.destroy
    end

    it "delete the namespace" do
      namespace_request = described_class.new(session_token: user.mediaflux_session, namespace: namespace_test)
      namespace_request.resolve
      expect(namespace_request.error?).to eq false
      expect(namespace_request.response_body).to eq mediaflux_response
    end
  end
end
