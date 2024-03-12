# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectMediaflux, type: :model, stub_mediaflux: true do
  let(:namespace_request) { instance_double(Mediaflux::Http::NamespaceCreateRequest, resolve: true, "error?": false) }
  let(:collection_request) { instance_double(Mediaflux::Http::CreateAssetRequest, id: 123) }
  let(:metadata_request) { instance_double(Mediaflux::Http::GetMetadataRequest, metadata: collection_metadata) }
  let(:parent_metadata_request) { instance_double(Mediaflux::Http::GetMetadataRequest, "error?": false) }
  let(:collection_metadata) { { id: "abc", name: "test", path: "td-demo-001/rc/test-ns/test", description: "description", namespace: "td-demo-001/rc/test-ns" } }
  let(:project) { FactoryBot.build :project }

  let(:create_asset_request) { instance_double(Mediaflux::Http::GetMetadataRequest) }

  describe "#create!" do
    before do
      allow(Mediaflux::Http::NamespaceCreateRequest).to receive(:new).with(session_token: "test-session-token",
                                                                           namespace: "/td-test-001/tigerdataNS/big-dataNS",
                                                                           description: "Namespace for project #{project.title}",
                                                                           store: "db").and_return(namespace_request)
      allow(Mediaflux::Http::CreateAssetRequest).to receive(:new).with(hash_including(session_token: "test-session-token", name: "big-data",
                                                                                      namespace: "/td-test-001/tigerdataNS/big-dataNS",
                                                                                      pid: "path=/td-test-001/tigerdata")).and_return(create_asset_request)
      allow(Mediaflux::Http::GetMetadataRequest).to receive(:new).with(hash_including(session_token: "test-session-token",
                                                                                      id: "path=/td-test-001/tigerdata")).and_return(parent_metadata_request)
      allow(create_asset_request).to receive(:resolve).and_return("<xml>...")
      allow(create_asset_request).to receive(:id).and_return("123")
    end

    context "it formats dates correctly for MediaFlux" do
      # Mediaflux dates are in UTC and look like this "07-Feb-2024 21:48:01"
      let(:project) { FactoryBot.build(:project, created_on: "2024-02-22T13:57:19-05:00", updated_on: "2024-02-26T13:57:19-05:00") }
      it "formats created_on and changes timezone to UTC as expected" do
        project_values = ProjectMediaflux.project_values(project: project)
        expect(project_values[:created_on]).to eq "22-FEB-2024 18:57:19"
      end
      it "formats updated_on as expected" do
        project_values = ProjectMediaflux.project_values(project: project)
        expect(project_values[:updated_on]).to eq "26-FEB-2024 13:57:19"
      end
    end

    it "creates a project namespace and collection and returns the mediaflux id" do
      mediaflux_id = described_class.create!(project: project, session_id: "test-session-token")
      expect(namespace_request).to have_received("error?")
      expect(parent_metadata_request).to have_received("error?")
      expect(create_asset_request).to have_received("id")
      expect(mediaflux_id).to be "123"
    end

    context "when the name is already taken" do
      let(:mediaflux_create_fixture_path) { Rails.root.join("spec", "fixtures", "files", "asset_create_error_response.xml") }
      let(:mediaflux_create_body) { Nokogiri::XML.parse(File.read(mediaflux_create_fixture_path)) }

      before do
        allow(create_asset_request).to receive(:id).and_return(nil)
        allow(create_asset_request).to receive(:response_xml).and_return(mediaflux_create_body)
      end

      it "raises an error" do
        expect do
          described_class.create!(project: project, session_id: "test-session-token")
        end.to raise_error(RuntimeError)
      end
    end

    context "when the parent colllection does not exist" do
      let(:parent_metadata_request) { instance_double(Mediaflux::Http::GetMetadataRequest, metadata: {}, "error?": true) }
      let(:parent_collection_request) { instance_double(Mediaflux::Http::CreateAssetRequest, id: 567, "error?": false) }

      before do
        allow(Mediaflux::Http::CreateAssetRequest).to receive(:new).with(hash_including(session_token: "test-session-token", name: "tigerdata",
                                                                                        namespace: "/td-test-001")).and_return(parent_collection_request)
      end

      it "creates a project namespace and collection and parent collection and returns the mediaflux id" do
        mediaflux_id = described_class.create!(project: project, session_id: "test-session-token")
        expect(namespace_request).to have_received("error?")
        expect(parent_collection_request).to have_received("error?")
        expect(create_asset_request).to have_received("id")
        expect(mediaflux_id).to be "123"
      end
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
