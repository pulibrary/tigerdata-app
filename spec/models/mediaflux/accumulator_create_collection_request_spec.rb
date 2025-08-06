# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::AccumulatorCreateCollectionRequest, connect_to_mediaflux: true, type: :model, integration: true do
  let(:mediaflux_url) { Mediaflux::Request.uri.to_s }
  let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:approved_project) { FactoryBot.create(:approved_project) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<response><reply type=\"result\"><result></result></reply></response>" }

  describe "#resolve" do
    before do
      # create a real collection for the test to create an accumulator for
      approved_project.mediaflux_id = nil
      @mediaflux_id = approved_project.approve!(current_user: user)
    end

    it "parses a response" do
      create_request = described_class.new(session_token: user.mediaflux_session, name: "testasset", collection: @mediaflux_id, type: "collection.asset.count")
      response = create_request.resolve
      expect(response.code).to eq("200")
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<name>testasset</name>")
      end).to have_been_made
    end
  end
end
