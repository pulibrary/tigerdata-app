# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::RangeQueryRequest, connect_to_mediaflux: true, type: :model do
  let!(:hc_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }
  let(:user) { hc_user }
  let(:approved_project) { FactoryBot.create(:approved_project) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<response><reply type=\"result\"><result></result></reply></response>" }

  before do
    # create a real collection for the test to create an accumulator for
    approved_project.mediaflux_id = nil
    @mediaflux_id = ProjectMediaflux.create!(project: approved_project,  user:)
    Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: @mediaflux_id, count: 70, pattern: "#{FFaker::Book.title}.txt").resolve
  end

  describe "#minimum" do
    it "returns the minimum value" do
      query_request = described_class.new(session_token: user.mediaflux_session, xpath: "content/size", collection: @mediaflux_id)
      expect(query_request.minimum).to eq(100)
    end
  end

  describe "#maximum" do
    it "returns the maximum value" do
      query_request = described_class.new(session_token: user.mediaflux_session, xpath: "content/size", collection: @mediaflux_id)
      expect(query_request.maximum).to eq(100)
    end
  end
end
