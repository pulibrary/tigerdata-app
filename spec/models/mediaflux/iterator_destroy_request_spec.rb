# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::IteratorDestroyRequest, connect_to_mediaflux: true, type: :model do
  let(:mediaflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:approved_project) { project_in_mediaflux(current_user: user) }

  describe "#result" do
    before do
      query_req = Mediaflux::QueryRequest.new(session_token: user.mediaflux_session, collection: approved_project.mediaflux_id, deep_search: true)
      @iterator_id = query_req.result
    end

    it "destroys an iterator" do
      destroy_request = described_class.new(session_token: user.mediaflux_session, iterator: @iterator_id)
      expect(destroy_request.result).to eq ""
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("service name=\"asset.query.iterator.destroy\"")
      end).to have_been_made
    end
  end
end
