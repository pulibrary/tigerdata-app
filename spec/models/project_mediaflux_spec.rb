# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectMediaflux, type: :model, stub_mediaflux: true do
  let(:namespace_request) { instance_double(Mediaflux::Http::NamespaceCreateRequest, resolve: true, "error?": false) }
  let(:collection_request) { instance_double(Mediaflux::Http::AssetCreateRequest, id: 123) }
  let(:metadata_request) { instance_double(Mediaflux::Http::AssetMetadataRequest, metadata: collection_metadata) }
  let(:parent_metadata_request) { instance_double(Mediaflux::Http::AssetMetadataRequest, "error?": false) }
  let(:collection_metadata) { { id: "abc", name: "test", path: "td-demo-001/rc/test-ns/test", description: "description", namespace: "td-demo-001/rc/test-ns" } }
  let(:project) { FactoryBot.build :project }
  let(:current_user) { FactoryBot.create(:user, uid: "jh1234") }
  let(:asset_create_request) { instance_double(Mediaflux::Http::AssetMetadataRequest) }

  describe "#create!" do
    context "Using test data" do
      before do
        allow(Mediaflux::Http::NamespaceCreateRequest).to receive(:new).with(session_token: "test-session-token",
                                                                            namespace: "/td-test-001/tigerdataNS/big-dataNS",
                                                                            description: "Namespace for project #{project.title}",
                                                                            store: "db").and_return(namespace_request)
        allow(Mediaflux::Http::AssetCreateRequest).to receive(:new).with(hash_including(session_token: "test-session-token", name: "big-data",
                                                                                        namespace: "/td-test-001/tigerdataNS/big-dataNS",
                                                                                        pid: "path=/td-test-001/tigerdata")).and_return(asset_create_request)
        allow(Mediaflux::Http::AssetMetadataRequest).to receive(:new).with(hash_including(session_token: "test-session-token",
                                                                                        id: "path=/td-test-001/tigerdata")).and_return(parent_metadata_request)
        allow(asset_create_request).to receive(:resolve).and_return("<xml>...")
        allow(asset_create_request).to receive(:id).and_return("123")
      end

      context "it formats dates correctly for MediaFlux" do
        let(:project) { FactoryBot.build(:project, created_on: "2024-02-22T13:57:19-05:00", updated_on: "2024-02-26T13:57:19-05:00") }
        it "formats created_on as expected" do
          project_values = ProjectMediaflux.project_values(project: project)
          expect(project_values[:created_on]).to eq "22-FEB-2024 13:57:19"
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
        expect(asset_create_request).to have_received("id")
        expect(mediaflux_id).to be "123"
      end

      context "when the name is already taken" do
        before do
          allow(asset_create_request).to receive(:id).and_return(nil)
          allow(asset_create_request).to receive(:response_error).and_return({message: "call to service 'asset.create' failed: The namespace /td-test-001/tigerdataNS/big-dataNS already contains an asset named 'big-data'"})
        end

        it "raises an error" do
          expect do
            described_class.create!(project: project, session_id: "test-session-token")
          end.to raise_error(StandardError) #Raises standard error when a duplicate project already exists
        end
      end

      context "when the parent colllection does not exist" do
        let(:parent_metadata_request) { instance_double(Mediaflux::Http::AssetMetadataRequest, metadata: {}, "error?": true) }
        let(:parent_collection_request) { instance_double(Mediaflux::Http::AssetCreateRequest, id: 567, "error?": false) }

        before do
          allow(Mediaflux::Http::AssetCreateRequest).to receive(:new).with(hash_including(session_token: "test-session-token", name: "tigerdata",
                                                                                          namespace: "/td-test-001")).and_return(parent_collection_request)
        end

        it "creates a project namespace and collection and parent collection and returns the mediaflux id" do
          mediaflux_id = described_class.create!(project: project, session_id: "test-session-token")
          expect(namespace_request).to have_received("error?")
          expect(parent_collection_request).to have_received("error?")
          expect(asset_create_request).to have_received("id")
          expect(mediaflux_id).to be "123"
        end
      end
    end
    context "when the metadata of a project is incomplete", connect_to_mediaflux: true do
      let(:incomplete_project) { FactoryBot.build(:project_with_dynamic_directory, project_id: '')}
      let(:project_metadata) {ProjectMetadata.new(current_user:, project: incomplete_project)}
      let(:namespace_request) {Mediaflux::Http::NamespaceCreateRequest}
      after do
        Mediaflux::Http::AssetDestroyRequest.new(session_token: current_user.mediaflux_session, collection: incomplete_project.mediaflux_id, members: true).resolve
      end
      it "should raise a MetadataError if any required is missing" do
        params = {mediaflux_id: 001,
                  project_directory: incomplete_project.metadata[:project_directory],
                  storage_capacity: {"size"=>{"approved"=>600, 
                  "requested"=>project.metadata[:storage_capacity][:size][:requested]}, 
                  "unit"=>{"approved"=>"GB", "requested"=>"GB"}},
                  event_note: "Other",
                  event_note_message: "Message filler"
                }
        project_metadata.approve_project(params:)
        session_token = current_user.mediaflux_session
        
        #raise a metadata error & log what specific required fields are missing when writing a project to mediaflux
        expect {
          incomplete_project.metadata_json["project_id"] = nil # we can no longer save the project without an id, so we have to reset it here to cause the error
          collection_id = ProjectMediaflux.create!(project: incomplete_project, session_id: session_token)
        }.to raise_error do |error|
          expect(error).to be_a(TigerData::MetadataError)
          expect(error.message).to include("Project creation failed with metadata schema version 0.6.1 due to the missing fields:")
          expect(incomplete_project.errors.attribute_names.size).to eq 1
          expect(incomplete_project.errors.attribute_names[0].to_s).to eq "base"
          expect(incomplete_project.errors.messages[:base]).to eq ["Invalid Project Metadata it does not match the schema 0.6.1\n Missing metadata value for project_id"]
        end
      end

      it "should raise a error if any error occurs in mediaflux" do
        params = {mediaflux_id: 001,
                  project_directory: incomplete_project.metadata[:project_directory],
                  storage_capacity: {"size"=>{"approved"=>600, 
                  "requested"=>project.metadata[:storage_capacity][:size][:requested]}, 
                  "unit"=>{"approved"=>"GB", "requested"=>"GB"}},
                  event_note: "Other",
                  event_note_message: "Message filler"
                }
        project_metadata.approve_project(params:)
        session_token = current_user.mediaflux_session
        
        #raise an error & log what was returned from mediaflux
        expect {
          collection_id = ProjectMediaflux.create!(project: incomplete_project, session_id: session_token)
        }.to raise_error do |error|
          expect(error).to be_a(StandardError)
          expect(error.message).to include("call to service 'asset.create' failed: XPath tigerdata:project/ProjectID is invalid: missing value")
        end
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
