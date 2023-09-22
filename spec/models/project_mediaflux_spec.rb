# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectMediaflux, type: :model do
  let(:namespace_request) { instance_double(Mediaflux::Http::NamespaceCreateRequest, resolve: true) }
  let(:collection_request) { instance_double(Mediaflux::Http::CreateAssetRequest, id: 123) }
  let(:metadata_request) { instance_double(Mediaflux::Http::GetMetadataRequest, metadata: collection_metadata) }
  let(:collection_metadata) { { id: "abc", name: "test", path: "td-demo-001/rc/test-ns/test", description: "description", namespace: "td-demo-001/rc/test-ns" } }
  let(:organization) { FactoryBot.build :organization }

  describe "#create!" do
    before do
      allow(Mediaflux::Http::NamespaceCreateRequest).to receive(:new).and_return(namespace_request)
      allow(Mediaflux::Http::CreateAssetRequest).to receive(:new).and_return(collection_request)
      allow(Mediaflux::Http::GetMetadataRequest).to receive(:new).and_return(metadata_request)
    end

    it "creates a project namespace and collection and loads the object" do
      project = described_class.create!("test", "test-store", organization, session_id: "123abc")
      expect(namespace_request).to have_received("resolve")
      expect(collection_request).to have_received("id")
      expect(metadata_request).to have_received("metadata")
      expect(project.id).to eq("abc")
      expect(project.name).to eq("test")
      expect(project.path).to eq("td-demo-001/rc/test-ns/test")
      expect(project.title).to eq("description")
      expect(project.organization).to eq(organization)
      expect(project.file_count).to eq(0)
      expect(project.store_name).to eq("test-store")
    end
  end

  describe "new" do
    let(:stores) do
      [{
        id: "1",
        type: "test",
        name: "default",
        tag: "test-tag"
      }]
    end
    let(:store_list_request) { instance_double(Mediaflux::Http::StoreListRequest, stores: stores) }

    before do
      allow(Mediaflux::Http::StoreListRequest).to receive(:new).and_return(store_list_request)
    end
    it "gets a default store" do
      project = described_class.new("id", "name", "path", "title", organization, session_id: "123abc")
      expect(project.store_name).to eq("default")
      expect(store_list_request).to have_received(:stores)
    end
  end

  describe "get" do
    let(:namespace_metadata) { { store: "mystore" } }
    let(:project_namespace_describe_request) { instance_double(Mediaflux::Http::NamespaceDescribeRequest, metadata: namespace_metadata) }
    let(:org_metadata) { { id: "1234", name: "test", path: "td-demo-001/rc", description: "description", namespace: "td-demo-001/rc/test-ns" } }
    let(:org_namespace_describe_request) { instance_double(Mediaflux::Http::NamespaceDescribeRequest, metadata: org_metadata) }

    before do
      allow(Mediaflux::Http::GetMetadataRequest).to receive(:new).with(id: "id", session_token: "123abc").and_return(metadata_request)
      allow(Mediaflux::Http::NamespaceDescribeRequest).to receive(:new).with(path: "td-demo-001/rc/test-ns", session_token: "123abc").and_return(project_namespace_describe_request)
      allow(Mediaflux::Http::NamespaceDescribeRequest).to receive(:new).with(path: "td-demo-001/rc", session_token: "123abc").and_return(org_namespace_describe_request)
      allow(Organization).to receive(:get).and_return(organization)
    end

    it "loads the metadata for the projects and the organization" do
      project = described_class.get("id", session_id: "123abc")
      expect(project.store_name).to eq("mystore")
      expect(Mediaflux::Http::GetMetadataRequest).to have_received(:new).with({ id: "id", session_token: "123abc" })
      expect(metadata_request).to have_received("metadata")
      expect(Organization).to have_received(:get).with(nil, session_id: "123abc", path: "td-demo-001/rc")
      expect(project.id).to eq("abc")
      expect(project.name).to eq("test")
      expect(project.path).to eq("td-demo-001/rc/test-ns/test")
      expect(project.title).to eq("description")
      expect(project.organization).to eq(organization)
      expect(project.file_count).to eq(nil)
      expect(project.store_name).to eq("mystore")
    end
  end
end
