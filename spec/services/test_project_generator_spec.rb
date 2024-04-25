# frozen_string_literal: true
require "rails_helper"

RSpec.describe TestProjectGenerator do
  let(:subject) { described_class.new(user:, number: 1, project_prefix: 'test-project') }
  let(:user) { FactoryBot.create :user }
  let(:user2) { FactoryBot.create :user }
  let(:user3) { FactoryBot.create :user }

  before do
    # make sure 3 users exist
    user2
    user3
  end

  describe "#generate" do

    let(:test_collection_create) { instance_double(Mediaflux::Http::AssetCreateRequest, resolve: true, id: "5678") }
    let(:test_namespace_describe) { instance_double(Mediaflux::Http::NamespaceDescribeRequest, "exists?": true)}   
    let(:test_store_list) { instance_double(Mediaflux::Http::StoreListRequest, stores: [{ id: "1", name: "db", tag: "", type: "database" }])}  
    let(:test_namespace_create) { instance_double(Mediaflux::Http::NamespaceCreateRequest, "error?": false) }
    let(:test_accum_count_create) { instance_double(Mediaflux::Http::CreateCollectionAccumulatorRequest, resolve: true) }
    let(:test_accum_size_create) { instance_double(Mediaflux::Http::CreateCollectionAccumulatorRequest, resolve: true) }
    let(:parent_metadata_request) { instance_double(Mediaflux::Http::GetMetadataRequest, "error?": false) }

    before do
      allow(user).to receive(:mediaflux_session).and_return("mediaflux_sessionid")
    end

    it "creates test data" do
      allow(Mediaflux::Http::AssetCreateRequest).to receive(:new).with(session_token: "mediaflux_sessionid", name: "test-project-00001", namespace: "/td-test-001/tigerdataNS/test-project-00001NS",
          tigerdata_values: {title: "Project  00001", updated_by: nil, updated_on: nil, code: "test-project-00001",
           created_by: user.uid, created_on: anything, data_manager: user2.uid, data_sponsor: user2.uid, data_user_read_only: [], data_user_read_write: [], 
           departments: ["HPC"], description: "Description of project test-project 00001", project_id: "doi-not-generated", project_purpose: "Research", status: "pending", storage_capacity: "500 GB", 
           storage_performance: "Standard", title: "Project test-project 00001", updated_by: nil, updated_on: nil}, 
          xml_namespace: "tigerdata", pid: "path=/td-test-001/tigerdata").and_return(test_collection_create)
      allow(Mediaflux::Http::NamespaceDescribeRequest).to receive(:new).with(session_token: "mediaflux_sessionid", path: "/td-test-001/tigerdataNS").and_return(test_namespace_describe)
      allow(Mediaflux::Http::StoreListRequest).to receive(:new).with(session_token: "mediaflux_sessionid").and_return(test_store_list)
      allow(Mediaflux::Http::NamespaceCreateRequest).to receive(:new).with(session_token: "mediaflux_sessionid", namespace: '/td-test-001/tigerdataNS/test-project-00001NS',description: "Namespace for project Project test-project 00001 (pending)", store:"db").and_return(test_namespace_create)
      allow(Mediaflux::Http::CreateCollectionAccumulatorRequest).to receive(:new).with(session_token: "mediaflux_sessionid", name: 'accum-count', collection: "5678", type: "collection.asset.count").and_return(test_accum_count_create)
      allow(Mediaflux::Http::CreateCollectionAccumulatorRequest).to receive(:new).with(session_token: "mediaflux_sessionid", name: 'accum-size', collection: "5678", type: "content.all.size").and_return(test_accum_size_create)
      allow(Mediaflux::Http::GetMetadataRequest).to receive(:new).with(hash_including(session_token: "mediaflux_sessionid", 
                                                                          id: "path=/td-test-001/tigerdata"
                                                                       )).and_return(parent_metadata_request)

      subject.generate
      expect(user).to have_received(:mediaflux_session)
      expect(test_collection_create).to have_received(:id)
      expect(test_namespace_describe).to have_received(:exists?)
      expect(test_namespace_create).to have_received(:error?)
      expect(parent_metadata_request).to have_received(:error?)
      expect(test_accum_size_create).to have_received(:resolve)
      expect(test_accum_count_create).to have_received(:resolve)
    end
  end
end
