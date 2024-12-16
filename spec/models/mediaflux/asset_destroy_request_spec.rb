# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::AssetDestroyRequest, connect_to_mediaflux: true, type: :model do
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:approved_project) { FactoryBot.create(:approved_project) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<response><reply type=\"result\"><result></result></reply></response>" }

  describe "#result" do
    before do
      # create a real collection for the test to attempt to destroy
      approved_project.mediaflux_id = nil
      @mediaflux_id = ProjectMediaflux.create!(project: approved_project, user:)
    end

    it "parses the result" do
      metadata_request = described_class.new(session_token: user.mediaflux_session, collection: @mediaflux_id, members: true)
      expect(metadata_request.error?).to eq false
      expect(metadata_request.response_body).to eq mediaflux_response
    end
  end
end
