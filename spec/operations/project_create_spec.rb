# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectCreate, type: :operation do
  let!(:approver) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  let(:valid_request) do
    Request.create(request_type: "new_project_request", request_title: "Request for Example Project", project_title: "Example Project",
                   data_sponsor: approver.uid, data_manager: approver.uid,
                   departments: [{ code: "dept", name: "department" }],
                   description: "description", parent_folder: random_project_directory,
                   project_folder: "project", project_id: "doi", quota: "500 GB",
                   requested_by: "uid", user_roles: [])
  end
  # let(:approver) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  subject { described_class.new } # Or initialize with dependencies if any

  describe "#call" do
    context "Success case" do
      it "creates a project and persists it in Mediaflux" do
        result = described_class.new.call(request: valid_request, approver: approver)

        expect(result).to be_success
        expect(result.value.mediaflux_id).not_to eq(0)
      end
    end

    context "Failure case" do
      it "raises an error if the project cannot be saved to Mediaflux" do
        allow_any_instance_of(Mediaflux::ProjectCreateServiceRequest).to receive(:resolve).and_return(double(mediaflux_id: 0, response_error: "Error saving project", debug_output: "Debug info"))

        expect do
          described_class.new.call(request: request, approver: approver)
        end.to raise_error(ProjectCreate::ProjectCreateError, /Error saving project/)
      end
    end
  end
end
