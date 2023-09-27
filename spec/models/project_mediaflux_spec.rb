# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectMediaflux, type: :model, stub_mediaflux: true do
  let(:namespace_request) { instance_double(Mediaflux::Http::NamespaceCreateRequest, resolve: true) }
  let(:collection_request) { instance_double(Mediaflux::Http::CreateAssetRequest, id: 123) }
  let(:metadata_request) { instance_double(Mediaflux::Http::GetMetadataRequest, metadata: collection_metadata) }
  let(:collection_metadata) { { id: "abc", name: "test", path: "td-demo-001/rc/test-ns/test", description: "description", namespace: "td-demo-001/rc/test-ns" } }
  let(:project) { FactoryBot.build :project }

  let(:create_asset_request) { instance_double(Mediaflux::Http::GetMetadataRequest) }

  describe "#create!" do
    before do
      allow(Mediaflux::Http::NamespaceCreateRequest).to receive(:new).and_return(namespace_request)
      allow(Mediaflux::Http::CreateAssetRequest).to receive(:new).and_return(create_asset_request)
      allow(create_asset_request).to receive(:resolve).and_return("<xml>...")
      allow(create_asset_request).to receive(:id).and_return("123")
    end

    it "creates a project namespace and collection and returns the mediaflux id" do
      mediaflux_id = described_class.create!(project: project, session_id: "test-session-token", created_by: "pul123")
      expect(namespace_request).to have_received("resolve")
      expect(create_asset_request).to have_received("resolve")
      expect(mediaflux_id).to be "123"
    end
  end

  describe "#safe_name" do
    it "handles special characters" do
      expect(described_class.safe_name("hello-world")).to eq "hello-world"
      expect(described_class.safe_name(" hello world 123")).to eq "hello-world-123"
      expect(described_class.safe_name("/hello/world")).to eq "-hello-world"
    end
  end
end
