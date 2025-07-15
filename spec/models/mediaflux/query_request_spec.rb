# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::QueryRequest, connect_to_mediaflux: true, type: :model do
  let!(:hc_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  let(:mediaflux_url) { Mediaflux::Request.uri.to_s }
  let(:user) { hc_user }
  let(:approved_project) { FactoryBot.create(:approved_project) }

  describe "#result" do
    before do
      approved_project.mediaflux_id = nil
      mediaflux_id = ProjectMediaflux.create!(project: approved_project, user:)
      Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: mediaflux_id).resolve
    end

    it "returns an iterator" do
      query_request = described_class.new(session_token: user.mediaflux_session, collection: @mediaflux_id)
      result = query_request.result
      expect(result).to eq(1)
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<service name=\"asset.query\"")
      end).to have_been_made.at_least_once
    end
  end

  context "deep search" do
    before do
      approved_project.mediaflux_id = nil
      mediaflux_id = ProjectMediaflux.create!(project: approved_project,  user:)
      Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: mediaflux_id).resolve
    end

    it "honors the deep search parameter" do
      query_request = described_class.new(session_token: user.mediaflux_session, collection: @mediaflux_id, deep_search: true)
      result = query_request.result
      expect(result).to eq(1)
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<service name=\"asset.query\"")
      end).to have_been_made.at_least_once
    end
  end

  context "action get-name" do
    before do
      approved_project.mediaflux_id = nil
      mediaflux_id = ProjectMediaflux.create!(project: approved_project, user:)
      Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: mediaflux_id).resolve
    end

    it "honors the get-name action" do
      query_request = described_class.new(session_token: user.mediaflux_session, collection: @mediaflux_id, action: "get-name")
      result = query_request.result
      expect(result).to eq(1)
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<service name=\"asset.query\"")
      end).to have_been_made.at_least_once
    end
  end

  context "action get-values" do
    before do
      approved_project.mediaflux_id = nil
      mediaflux_id = ProjectMediaflux.create!(project: approved_project, user:)
      Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: mediaflux_id).resolve
    end

    it "request the custom fields when using get-values" do
      query_request = described_class.new(session_token: user.mediaflux_session, collection: @mediaflux_id, action: "get-values")
      result = query_request.result
      expect(result).to eq(1)
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<service name=\"asset.query\"")
      end).to have_been_made.at_least_once
    end
  end
end
