# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::TestAssetCreateRequest, connect_to_mediaflux: true, type: :model do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:approved_project) { FactoryBot.create(:approved_project) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<response><reply type=\"result\"><result></result></reply></response>" }
  # let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }

  describe "#resolve" do
    before do
      # create a collection for the test to create files under
      approved_project.mediaflux_id = nil
      @mediaflux_id = ProjectMediaflux.create!(project: approved_project, user:)
    end

    it "disconnects the session",
    :integration do
      namespace_request = described_class.new(session_token: user.mediaflux_session, parent_id: @mediaflux_id, count: 20, pattern: "abc")
      namespace_request.resolve
      expect(namespace_request.error?).to eq false
      expect(namespace_request.response_body).to eq mediaflux_response
    end
  end
end
