# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::AssetDestroyRequest, connect_to_mediaflux: true, type: :model do
  let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:approved_project) {  project_in_mediaflux(current_user: user) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<response><reply type=\"result\"><result></result></reply></response>" }

  describe "#result" do

    it "parses the result",
    :integration do
      metadata_request = described_class.new(session_token: user.mediaflux_session, collection: approved_project.mediaflux_id, members: true)
      expect(metadata_request.error?).to eq false
      expect(metadata_request.response_body).to eq mediaflux_response
    end
  end
end
