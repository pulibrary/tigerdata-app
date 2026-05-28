# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::IteratorRequest, connect_to_mediaflux: true, type: :model do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:mediaflux_url) { Mediaflux::Request.uri.to_s }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:approved_project) { test_project_from_path("/princeton/tigerdata/RDSS/Query/CProject") }

  describe "#result" do
    before do
      mediaflux_id = approved_project.mediaflux_id

      query_req = Mediaflux::QueryRequest.new(session_token: user.mediaflux_session, collection: mediaflux_id, deep_search: false)
      @iterator_id = query_req.result
    end

    it "returns asset information",
    :integration do
      query_request = described_class.new(session_token: user.mediaflux_session, iterator: @iterator_id, action: "get-values")
      result = query_request.result
      expect(result[:files].count).to eq 10
      expect(result[:files][0].name).to eq "A0"
      expect(result[:files][0].path).to eq "/princeton/tigerdata/RDSS/Query/CProject/A0"
      expect(result[:files][0].size).to eq 10
      expect(result[:files][0].last_modified.class).to eq ActiveSupport::TimeWithZone
      expect(result[:files][0].created_on.class).to eq ActiveSupport::TimeWithZone
      # byebug
      expect(result[:files][0].created_by.values).to eq ["manager", "", "system"]
      expect(result[:files][9].name).to eq "n_10000"
      expect(result[:files][9].path).to eq "/princeton/tigerdata/RDSS/Query/CProject/n_10000"
      expect(result[:files][9].size).to eq 0
      expect(result[:files][9].last_modified.class).to eq ActiveSupport::TimeWithZone
      expect(result[:files][9].created_on.class).to eq ActiveSupport::TimeWithZone
      expect(result[:files][9].created_by.values).to eq ["manager", "", "system"]
      expect(result[:complete]).to eq true
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<service name=\"asset.query.iterate\"")
      end).to have_been_made.at_least_once
    end
  end

  describe "action get-names" do
    before do
      mediaflux_id = approved_project.mediaflux_id

      query_req = Mediaflux::QueryRequest.new(session_token: user.mediaflux_session, collection: mediaflux_id, deep_search: true)
      @iterator_id = query_req.result
    end

    it "returns basic asset information",
    :integration do
      query_request = described_class.new(session_token: user.mediaflux_session, iterator: @iterator_id, action: "get-name")
      result = query_request.result
      expect(result[:count]).to eq 100
      expect(result[:complete]).to eq false
      expect(result[:files].first.name).to eq("A0")
      expect(result[:files].last.name).to eq("E13")
      expect(result[:files].count(&:collection)).to eq 1
      expect(a_request(:post, mediaflux_url).with do |req|
        req.body.include?("<service name=\"asset.query.iterate\"")
      end).to have_been_made.at_least_once
    end
  end

  describe "#action get-meta" do
    # allow one test to create the asset so we test the getting of assets with no names
    let(:approved_project) { create_project_in_mediaflux(current_user: user) }

    before do
      mediaflux_id = approved_project.mediaflux_id

      asset_req = Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: mediaflux_id)
      asset_response = asset_req.response_body.split("<id>")[1]
      @asset_id = asset_response.split("<")[0].to_i
      asset_req.resolve # intentionally making a second asset

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
