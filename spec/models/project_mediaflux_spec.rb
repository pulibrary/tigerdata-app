# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectMediaflux, type: :model do
  let(:collection_metadata) { { id: "abc", name: "test", path: "/td-demo-001/rc/test-ns/test", description: "description", namespace: "/td-demo-001/rc/test-ns" } }
  let(:project) { FactoryBot.build :project_with_doi }
  let!(:hc_user) { FactoryBot.create(:project_sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  let(:current_user) { hc_user }

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

        project_directory_postfix = project.metadata_model.project_directory.split("/").last
        expect(namespace_metadata[:path]).to end_with(project_directory_postfix + "NS")
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
          duplicate_events = project.provenance_events.where(event_type: "Debug Output").find { |event| event.event_note.include?("Collection already exists") }
          expect(duplicate_events).to be nil

          # Try to create the same project again
          described_class.create!(project: project, user: current_user)
          duplicate_events = project.provenance_events.where(event_type: "Debug Output").find { |event| event.event_note.include?("Collection already exists") }
          expect(duplicate_events).not_to be nil
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
        project.approve!(current_user: current_user)

        # raise a metadata error & log what specific required fields are missing when writing a project to mediaflux
        # rubocop:disable Style/MultilineBlockChain
        expect do
          incomplete_project.metadata_model.project_id = nil # we can no longer save the project without an id, so we have to reset it here to cause the error
          ProjectMediaflux.create!(project: incomplete_project, user: current_user)
        end.to raise_error do |error|
          # TODO: We are catching the ActiveRecord exception here but the save to Mediaflux also detects the missing
          # `project-id` and we should be testing for that too. I believe that's what the original code checking for
          # TigerData::MetadataError was doing but since the save process has changed the original exception is not
          # being thrown anymore.
          expect(error).to be_a(ActiveRecord::RecordInvalid)
          expect(error.message).to include("Invalid Project Metadata it does not match the schema 0.6.1\n Missing metadata value for project_id")
        end
        # rubocop:enable Style/MultilineBlockChain
      end

      it "should raise a error if any error occurs in mediaflux" do
        incomplete_project.approve!(current_user: current_user)
        # TODO: We are handling errors different from before.
        # Revisit if we want to throw an exception.
        ProjectMediaflux.create!(project: incomplete_project, user: current_user)
        errors = incomplete_project.provenance_events.select { |event| (event.event_note || "").include?("call to service 'tigerdata.project.create' failed: XPath args/project-id is invalid") }
        expect(errors.count > 0).to be true
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
