# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectMediaflux, type: :model do
  let(:collection_metadata) { { id: "abc", name: "test", path: "/td-demo-001/rc/test-ns/test", description: "description", namespace: "/td-demo-001/rc/test-ns" } }
  let(:project) { FactoryBot.build :project_with_doi }
  let(:current_user) { FactoryBot.create(:user, uid: "jh1234", mediaflux_session: SystemUser.mediaflux_session) }

  describe "#create!", connect_to_mediaflux: true do
    context "Using test data" do
      it "creates a project namespace and collection and returns the mediaflux id" do
        mediaflux_id = described_class.create!(project: project, user: current_user)
        mediaflux_metadata = Mediaflux::AssetMetadataRequest.new(
                              session_token: current_user.mediaflux_session,
                              id: mediaflux_id
                            ).metadata
        namespace_path = mediaflux_metadata[:namespace]
        namespace_metadata = Mediaflux::NamespaceDescribeRequest.new(
                              session_token: current_user.mediaflux_session,
                              path: namespace_path
                            ).metadata
        expect(namespace_metadata[:description]).to match(/Namespace for/)
      end

      describe "quota", connect_to_mediaflux: true do
        it "adds a quota when it creates a project in mediaflux" do
          project = FactoryBot.create(:project_with_doi)
          described_class.create!(project: project, user: current_user)
          metadata = Mediaflux::AssetMetadataRequest.new(
            session_token: current_user.mediaflux_session,
            id: project.mediaflux_id
          ).metadata
          expect(metadata[:quota_allocation]).not_to be_empty
          expect(metadata[:quota_allocation]).to eq("500 GB")
        end
      end

      context "when the name is already taken" do
        it "raises an error" do
          # Make the project once
          described_class.create!(project: project, user: current_user)
          # It should raise a duplicate namespace error the second time
          expect do
            described_class.create!(project: project, user: current_user)
          end.to raise_error(MediafluxDuplicateNamespaceError) # Raises custom error when a duplicate project already exists
        end
      end

      context "when the parent colllection does not exist" do
        let(:mediaflux_id) { described_class.create!(project: project, user: current_user) }
        let(:mediaflux_metadata) do
          Mediaflux::AssetMetadataRequest.new(
                             session_token: current_user.mediaflux_session,
                             id: mediaflux_id
                           ).metadata
        end
        let(:project_parent) { Rails.configuration.mediaflux["api_root_collection"] }

        it "creates a project namespace" do
          namespace_path = mediaflux_metadata[:namespace]
          namespace_metadata = Mediaflux::NamespaceDescribeRequest.new(
            session_token: current_user.mediaflux_session,
            path: namespace_path
          ).metadata

          expect(namespace_metadata[:description]).to match(/Namespace for/)
        end

        it "creates a collection" do
          expect(mediaflux_metadata[:collection]).to eq true
        end

        it "creates a parent collection" do
          parent_collection_metadata = Mediaflux::AssetMetadataRequest.new(
                                        session_token: current_user.mediaflux_session,
                                        id: project_parent
                                      ).metadata
          expect(parent_collection_metadata[:path]).to eq project_parent.gsub("path=", "")
        end
      end
    end
    context "when the metadata of a project is incomplete", connect_to_mediaflux: true do
      let(:incomplete_project) { FactoryBot.build(:project_with_dynamic_directory, project_id: "") }
      let(:project_metadata) { incomplete_project.metadata_model }
      let(:namespace_request) { Mediaflux::NamespaceCreateRequest }
      after do
        Mediaflux::AssetDestroyRequest.new(session_token: current_user.mediaflux_session, collection: incomplete_project.mediaflux_id, members: true).resolve
      end
      it "should raise a MetadataError if project is invalid" do
        mediaflux_id = 1001
        project.approve!(mediaflux_id: mediaflux_id, current_user: current_user)

        # raise a metadata error & log what specific required fields are missing when writing a project to mediaflux
        # rubocop:disable Style/MultilineBlockChain
        expect do
          incomplete_project.metadata_model.project_id = nil # we can no longer save the project without an id, so we have to reset it here to cause the error
          ProjectMediaflux.create!(project: incomplete_project, user: current_user)
        end.to raise_error do |error|
          expect(error).to be_a(TigerData::MetadataError)
          expect(error.message).to include("Project creation failed with metadata schema version 0.6.1 due to the missing fields:")
          expect(incomplete_project.errors.attribute_names.size).to eq 1
          expect(incomplete_project.errors.attribute_names[0].to_s).to eq "base"
          expect(incomplete_project.errors.messages[:base]).to eq ["Invalid Project Metadata it does not match the schema 0.6.1\n Missing metadata value for project_id"]
        end
        # rubocop:enable Style/MultilineBlockChain
      end

      it "should raise a error if any error occurs in mediaflux" do
        mediaflux_id = 1001
        incomplete_project.approve!(mediaflux_id: mediaflux_id, current_user: current_user)

        # raise an error & log what was returned from mediaflux
        # rubocop:disable Style/MultilineBlockChain
        expect do
          ProjectMediaflux.create!(project: incomplete_project, user: current_user)
        end.to raise_error do |error|
          expect(error).to be_a(StandardError)
          expect(error.message).to include("call to service 'asset.create' failed: XPath tigerdata:project/ProjectID is invalid: missing value")
        end
        # rubocop:enable Style/MultilineBlockChain
      end
    end
  end

  describe "#update", connect_to_mediaflux: true do
    before do
      described_class.create!(project: project, user: current_user)
    end
    it "defaults updated_on/by when not provided" do
      project.metadata_model.updated_on = nil
      project.metadata_model.updated_by = nil
      described_class.update(project: project, user: current_user)
      expect(project.metadata_model.updated_on).not_to be nil
      expect(project.metadata_model.updated_by).not_to be nil
    end

    it "honors updated_on/by values when provided" do
      updated_on = Time.current.in_time_zone("America/New_York").iso8601
      project.metadata_model.updated_on = updated_on
      project.metadata_model.updated_by = "user123"
      described_class.update(project: project, user: current_user)
      expect(project.metadata_model.updated_on).to eq updated_on
      expect(project.metadata_model.updated_by).to eq "user123"
    end
  end
end
