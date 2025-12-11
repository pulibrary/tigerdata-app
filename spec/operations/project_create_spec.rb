# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectCreate, type: :operation, integration: true do
  let!(:approver) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:valid_request) do
    Request.create(request_type: "new_project_request", request_title: "Request for Example Project", project_title: "Example Project",
                   data_sponsor: approver.uid, data_manager: approver.uid,
                   departments: [{ code: "dept", name: "department" }],
                   description: "description", parent_folder: random_project_directory,
                   project_folder: "project", project_id: "doi", quota: "500 GB",
                   requested_by: "uid", user_roles: [])
  end

  let(:valid_request_with_roles) do
    Request.create(request_type: "new_project_request", request_title: "Request for Example Project", project_title: "Example Project",
                   data_sponsor: approver.uid, data_manager: approver.uid,
                   departments: [{ code: "dept", name: "department" }],
                   description: "description", parent_folder: random_project_directory,
                   project_folder: "project", project_id: "doi", quota: "500 GB",
                   requested_by: "uid", user_roles: [{ uid: "cac9", read_only: true }])
  end

  let(:invalid_request) do
    Request.create(request_type: "new_project_request", request_title: "Request for Example Project", project_title: "Example Project",
                   data_sponsor: approver.uid, data_manager: approver.uid,
                   departments: [{ code: "dept", name: "department" }],
                   description: "description", parent_folder: random_project_directory,
                   project_folder: "project", project_id: "doi", quota: "not-valid", # quota is not valid
                   requested_by: "uid", user_roles: [])
  end
  subject { described_class.new } # Or initialize with dependencies if any

  describe "#call" do
    context "Success case" do
      it "creates a project and persists it in Mediaflux" do
        result = described_class.new.call(request: valid_request, approver: approver)
        expect(result).to be_success
        project = result.value!
        expect(project.mediaflux_id).not_to eq(0)
      end

      it "creates a project and persists it in Mediaflux with the user roles" do
        FactoryBot.create(:user, uid: "cac9")
        result = described_class.new.call(request: valid_request_with_roles, approver: approver)
        expect(result).to be_success
        project = result.value!
        expect(project.mediaflux_id).not_to eq(0)
      end
    end

    context "Failure cases" do
      it "returns a failure for non-EOF errors if the project cannot be saved to Mediaflux" do
        expect do
          result = described_class.new.call(request: invalid_request, approver: approver)
          expect(result).not_to be_success
          error_message = result.failure
          expect(error_message).to include("Error saving project")
        end.to change { Project.count }.by(1)
      end

      it "returns a failure if the doi can not be minted" do
        allow(PULDatacite).to receive(:publish_test_doi?).and_raise("DOI error")
        result = described_class.new.call(request: invalid_request, approver: approver)
        expect(result).not_to be_success

        error_message = result.failure
        expect(error_message).to eq("Error creating the project: DOI error")
      end

      it "returns a failure if the project can not be updated" do
        project = FactoryBot.create(:approved_project)
        allow(Project).to receive(:"create!").and_return(project)
        allow(project).to receive(:"mediaflux_id=").and_raise("Object issue")
        result = described_class.new.call(request: invalid_request, approver: approver)
        expect(result).not_to be_success

        error_message = result.failure
        expect(error_message).to include("Setting the mediaflux id the")
      end

      it "returns a failure if the project can not be activated" do
        project = FactoryBot.create(:approved_project)
        allow(Project).to receive(:"create!").and_return(project)
        allow(project).to receive(:activate).and_raise("Object issue")
        result = described_class.new.call(request: invalid_request, approver: approver)
        expect(result).not_to be_success

        error_message = result.failure
        expect(error_message).to include("Error activate project")
      end

      it "retries on EOFError when persisting to Mediaflux" do
        project_metadata_json = RequestProjectMetadata.convert(valid_request)
        # Link the request to the project
        project = Project.create!({ metadata_json: project_metadata_json })
        mediaflux_request = Mediaflux::ProjectCreateServiceRequest.new(session_token: approver.mediaflux_session, project: project)
        allow(Mediaflux::ProjectCreateServiceRequest).to receive(:new).and_return(mediaflux_request)
        project_create_operation = described_class.new

        error_count = 0
        allow(mediaflux_request).to receive(:resolve).and_wrap_original do |original_method, *args|
          if error_count == 0
            # Force an error the first time to make sure the retry is invoked in the code
            error_count = 1
            raise EOFError, "error"
          else
            original_method.call(*args)
          end
        end

        result = project_create_operation.call(request: valid_request, approver: approver)

        expect(mediaflux_request).to have_received(:resolve).twice

        expect(result).to be_success
        expect(result.value!.mediaflux_id).not_to eq(0)
      end

      it "Fails on mulitple EOFError's when persisting to Mediaflux" do
        project_metadata_json = RequestProjectMetadata.convert(valid_request)
        # Link the request to the project
        project = Project.create!({ metadata_json: project_metadata_json })
        mediaflux_request = Mediaflux::ProjectCreateServiceRequest.new(session_token: approver.mediaflux_session, project: project)
        allow(Mediaflux::ProjectCreateServiceRequest).to receive(:new).and_return(mediaflux_request)
        project_create_operation = described_class.new

        error_count = 0
        allow(mediaflux_request).to receive(:resolve).and_raise EOFError

        result = project_create_operation.call(request: valid_request, approver: approver)

        expect(mediaflux_request).to have_received(:resolve).exactly(3).times

        expect(result).to_not be_success
      end
    end
  end
end
