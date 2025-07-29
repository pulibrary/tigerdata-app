# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectMediaflux, type: :model do
  let(:project) { FactoryBot.build :project_with_doi }
  let!(:current_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }

  describe "#create!", connect_to_mediaflux: true do
    context "Using test data" do
      it "creates a project namespace and collection and returns the mediaflux id",
      :integration do
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
        it "adds a quota when it creates a project in mediaflux",
        :integration do
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
        it "raises an error",
        :integration do
          # Make the project once
          described_class.create!(project: project, user: current_user)
          duplicate_events = project.provenance_events.where(event_type: "Debug Output").find { |event| event.event_note.include?("Collection already exists") }
          expect(duplicate_events).to be nil

          # Raises an error if we try to create the same project again
          expect { described_class.create!(project: project, user: current_user) }.to raise_error(Project::ProjectCreateError)
        end
      end
    end
    context "when the metadata of a project is incomplete", connect_to_mediaflux: true do
      let(:incomplete_project) do
        test_project = FactoryBot.build(:project_with_dynamic_directory, project_id: "")
        test_project.metadata_model.project_id = nil
        test_project
      end
      it "should raise a MetadataError if project is invalid" do
        project.create!(initial_metadata: incomplete_project.metadata_model, user: current_user)

        expect(project.valid?).to be false
        expect(project.errors.first).to be_a(ActiveModel::Error)
        expect(project.errors.first.type).to include("Invalid Project Metadata it does not match the schema 0.6.1\n Missing metadata value for project_id")
      end

      it "should raise a error if any error occurs in mediaflux" do
        expect { incomplete_project.approve!(current_user: current_user) }.to raise_error(Project::ProjectCreateError)
      end
    end
  end

  describe "#update", connect_to_mediaflux: true do
    before do
      described_class.create!(project: project, user: current_user)
    end
    it "defaults updated_on/by when not provided",
    :integration do
      project.metadata_model.updated_on = nil
      project.metadata_model.updated_by = nil
      described_class.update(project: project, user: current_user)
      expect(project.metadata_model.updated_on).not_to be nil
      expect(project.metadata_model.updated_by).not_to be nil
    end

    it "honors updated_on/by values when provided",
    :integration do
      updated_on = Time.current.in_time_zone("America/New_York").iso8601
      project.metadata_model.updated_on = updated_on
      project.metadata_model.updated_by = "user123"
      described_class.update(project: project, user: current_user)
      expect(project.metadata_model.updated_on).to eq updated_on
      expect(project.metadata_model.updated_by).to eq "user123"
    end
  end
end
