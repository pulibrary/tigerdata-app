# frozen_string_literal: true
require "rails_helper"

RSpec.describe TestAssetGenerator do
  let(:subject) { described_class.new(user:, project_id: project.id, levels: 1, directory_per_level: 1, file_count_per_directory: 1) }
  let(:project) { FactoryBot.create :project, mediaflux_id: 1234 }
  let(:user) { FactoryBot.create :user }

  describe "#generate" do

    let(:test_asset_create) { instance_double(Mediaflux::Http::TestAssetCreateRequest, resolve: true) }

    before do
      allow(user).to receive(:mediaflux_session).and_return("mediaflux_sessionid")
    end

    it "creates test data" do
      allow(Mediaflux::Http::TestAssetCreateRequest).to receive(:new).with(session_token: "mediaflux_sessionid", parent_id: 1234, count: 1).and_return(test_asset_create)
      subject.generate
      expect(user).to have_received(:mediaflux_session)
      expect(test_asset_create).to have_received(:resolve)
    end

    context "multiple files" do
      let(:subject) { described_class.new(user:, project_id: project.id, levels: 1, directory_per_level: 1, file_count_per_directory: 3) }

      it "creates test data" do
        allow(Mediaflux::Http::TestAssetCreateRequest).to receive(:new).with(session_token: "mediaflux_sessionid", parent_id: 1234, count: 3).and_return(test_asset_create)
        subject.generate
        expect(user).to have_received(:mediaflux_session)
        expect(test_asset_create).to have_received(:resolve)
      end
    end

    context "Multiple levels" do
      let(:subject) { described_class.new(user:, project_id: project.id, levels: 2, directory_per_level: 1, file_count_per_directory: 1) }
      let(:test_collection_create) { instance_double(Mediaflux::Http::CreateAssetRequest, id: "5678") }

      it "creates collections and files" do
        allow(Mediaflux::Http::CreateAssetRequest).to receive(:new).with(session_token: "mediaflux_sessionid", pid: 1234, name: anything).and_return(test_collection_create)
        allow(Mediaflux::Http::TestAssetCreateRequest).to receive(:new).with(session_token: "mediaflux_sessionid", parent_id: "5678", count: 1).and_return(test_asset_create)
        allow(Mediaflux::Http::TestAssetCreateRequest).to receive(:new).with(session_token: "mediaflux_sessionid", parent_id: 1234, count: 1).and_return(test_asset_create)
        subject.generate
        expect(user).to have_received(:mediaflux_session).exactly(3).times
        expect(test_asset_create).to have_received(:resolve).twice
        expect(test_collection_create).to have_received(:id)
      end
    end
  end
end
