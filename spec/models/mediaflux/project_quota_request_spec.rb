# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ProjectQuotaRequest, connect_to_mediaflux: true, type: :model do
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }

  describe "#quota" do
    it "query for a known project in Mediaflux" do
      # This is a know project in our Docker image
      asset_id = "path=/princeton/tigerdata/RDSS/testing-project"
      request = described_class.new(session_token: user.mediaflux_session, asset_id: asset_id)
      quota = request.quota
      expect(quota[:project_files]).to eq 200
      expect(quota[:project_files_human]).to eq "200 bytes"
    end
  end
end
