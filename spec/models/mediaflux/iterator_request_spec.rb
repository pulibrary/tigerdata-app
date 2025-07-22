# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::IteratorRequest, connect_to_mediaflux: true, type: :model do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  let(:mediaflux_url) { Mediaflux::Request.uri.to_s }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:approved_project) { FactoryBot.create(:approved_project) }

  describe "#result" do
    before do
      approved_project.mediaflux_id = nil
      mediaflux_id = ProjectMediaflux.create!(project: approved_project, user:)

      asset_req = Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: mediaflux_id)
      asset_response = asset_req.response_body.split("<id>")[1]
      @asset_id = asset_response.split("<")[0].to_i
      asset_req.resolve

      query_req = Mediaflux::QueryRequest.new(session_token: user.mediaflux_session, collection: mediaflux_id, deep_search: true)
      @iterator_id = query_req.result
    end

    it "returns asset information",
    :integration do
      query_request = described_class.new(session_token: user.mediaflux_session, iterator: @iterator_id, action: "get-values")
      result = query_request.result
      expect(result[:files][0].name).to eq "__asset_id__#{@asset_id}"
      expect(result[:files][0].path).to eq "/princeton/#{approved_project.metadata_model.project_directory}/__asset_id__#{@asset_id}"
      expect(result[:files][0].size).to eq 100
      expect(result[:files].count).to eq 2
      expect(result[:complete]).to eq true
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<service name=\"asset.query.iterate\"")
      end).to have_been_made.at_least_once
    end
  end

  describe "action get-names" do
    before do
      approved_project.mediaflux_id = nil
      mediaflux_id = ProjectMediaflux.create!(project: approved_project, user:)

      asset_req = Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: mediaflux_id)
      asset_response = asset_req.response_body.split("<id>")[1]
      @asset_id = asset_response.split("<")[0].to_i
      asset_req.resolve

      query_req = Mediaflux::QueryRequest.new(session_token: user.mediaflux_session, collection: mediaflux_id, deep_search: true)
      @iterator_id = query_req.result
    end

    it "returns basic asset information",
    :integration do
      query_request = described_class.new(session_token: user.mediaflux_session, iterator: @iterator_id, action: "get-name")
      result = query_request.result
      expect(result.count).to eq 3
      expect(result[:complete]).to eq true
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<service name=\"asset.query.iterate\"")
      end).to have_been_made.at_least_once
    end
  end

  describe "#action get-meta" do
    before do
      approved_project.mediaflux_id = nil
      mediaflux_id = ProjectMediaflux.create!(project: approved_project, user:)

      asset_req = Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: mediaflux_id)
      asset_response = asset_req.response_body.split("<id>")[1]
      @asset_id = asset_response.split("<")[0].to_i
      asset_req.resolve

      query_req = Mediaflux::QueryRequest.new(session_token: user.mediaflux_session, collection: mediaflux_id, deep_search: true)
      @iterator_id = query_req.result
    end

    it "returns asset information",
    :integration do
      query_request = described_class.new(session_token: user.mediaflux_session, iterator: @iterator_id, action: "get-meta")
      result = query_request.result
      expect(result[:files][0].name).to eq "__asset_id__#{@asset_id}"
      expect(result[:files][0].path).to eq "/princeton/#{approved_project.metadata_model.project_directory}/__asset_id__#{@asset_id}"
      expect(result[:files].count).to eq 2
      expect(result[:complete]).to eq true
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<service name=\"asset.query.iterate\"")
      end).to have_been_made.at_least_once
    end
  end
end
