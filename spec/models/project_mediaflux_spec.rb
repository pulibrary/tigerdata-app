# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectMediaflux, type: :model do
  let(:project) do
    request = FactoryBot.create(:request_project)
    request.approve(current_user)
  end

  let!(:current_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  describe "#create!", connect_to_mediaflux: true do
    context "Using test data" do
      it "creates a project namespace and collection and returns the mediaflux id",
      :integration do
        mediaflux_id = project.mediaflux_id
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
          metadata = Mediaflux::AssetMetadataRequest.new(
            session_token: current_user.mediaflux_session,
            id: project.mediaflux_id
          ).metadata
          expect(metadata[:quota_allocation]).not_to be_empty
          expect(metadata[:quota_allocation]).to eq("500 GB")
        end
      end
    end

    context "when the metadata of a project is incomplete", connect_to_mediaflux: true do
      let(:incomplete_request) do
        request = FactoryBot.create(:request_project)
        request.project_title = nil
        request
      end

      let(:incomplete_project) do
        request = FactoryBot.create(:request_project)
        incomplete_project = request.approve(current_user)
        incomplete_project.metadata_model.project_id = nil
        incomplete_project
      end

      it "should raise a MetadataError if project is invalid", integration: true do
        project.create!(initial_metadata: incomplete_project.metadata_model, user: current_user)

        expect(project.valid?).to be false
        expect(project.errors.first).to be_a(ActiveModel::Error)
        expect(project.errors.first.type).to include("Invalid Project Metadata it does not match the schema 0.6.1\n Missing metadata value for project_id")
      end

      it "should raise a error if any error occurs in mediaflux", integration: true do
        expect { incomplete_request.approve(current_user) }.to raise_error(ProjectCreate::ProjectCreateError)
      end
    end
  end

  describe "#update", connect_to_mediaflux: true do
    before do
      described_class.create!(project: project, user: current_user)
    end
    # Project updates in MediaFlux are not supported yet
    xit "defaults updated_on/by when not provided",
    :integration do
      project.metadata_model.updated_on = nil
      project.metadata_model.updated_by = nil
      described_class.update(project: project, user: current_user)
      expect(project.metadata_model.updated_on).not_to be nil
      expect(project.metadata_model.updated_by).not_to be nil
    end

    # Project updates in MediaFlux are not supported yet
    xit "honors updated_on/by values when provided",
    :integration do
      updated_on = Time.current.in_time_zone("America/New_York").iso8601
      project.metadata_model.updated_on = updated_on
      project.metadata_model.updated_by = "user123"
      described_class.update(project: project, user: current_user)
      expect(project.metadata_model.updated_on).to eq updated_on
      expect(project.metadata_model.updated_by).to eq "user123"
    end
  end

  describe "#xml_payload" do
    let(:project_not_in_mediaflux) { FactoryBot.create :project_with_doi }

    it "raises errors when project is not accessible", :integration do
      # The project is not in mediaflux and therefore this will raise an exception
      expect { described_class.xml_payload(project: project_not_in_mediaflux, user: current_user) }.to raise_error(StandardError)
    end
  end
end
