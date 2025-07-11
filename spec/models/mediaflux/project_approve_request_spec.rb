# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ProjectApproveRequest, type: :model, connect_to_mediaflux: true do
  let(:approver) { FactoryBot.create :sysadmin, mediaflux_session: SystemUser.mediaflux_session }
  let(:session_id) { approver.mediaflux_session }
  let(:approved_project) do
    project = FactoryBot.create :approved_project
    mediaflux_id = project.save_in_mediaflux(user: approver)
    data_sponsor = User.find_by(uid: project.metadata_model.data_sponsor)
    ProvenanceEvent.generate_submission_events(project: project, user: data_sponsor)
    project.metadata_model.project_directory = "approved_project"
    project.metadata_model.storage_capacity = { size: { requested: 200, approved: 100 }, unit: { requested: "PB", approved: "TB" } }
    project.metadata_model.storage_performance_expectations = { requested: "Standard", approved: "Fast" }
    project.mediaflux_id = mediaflux_id
    project.approve!(current_user: approver, mediaflux_id:)
    project
  end

  let(:approve_request_xml) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_approve_request.xml")
    File.new(filename).read
  end

  let(:approve_response_xml) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_approve_response.xml")
    File.new(filename).read
  end

  describe "#resolve" do
    # TODO: I don't think we need Mediaflux::AssetMetadataRequest anymore.
    # If so we could remove it and this test too.
    xit "updates the submission" do
      approve_request = described_class.new(session_token: session_id, project: approved_project)
      approve_request.resolve
      req = Mediaflux::AssetMetadataRequest.new(session_token: session_id, id: approved_project.mediaflux_id)
      metadata  = req.metadata
      expect(req.error?).to be_falsey
      # TODO: Uncomment when the approve request is implemented to the tigerdata:project schema
      # approval = approved_project.provenance_events.find_by(event_type: ProvenanceEvent::APPROVAL_EVENT_TYPE)
      # expect(metadata[:submission][:approved_by]).to eq(approval.event_person)
      # submission = approved_project.provenance_events.find_by(event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE)
      # expect(metadata[:submission][:requested_by]).to eq(submission.event_person)
    end
  end
end
