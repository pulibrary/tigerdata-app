# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::ProjectApproveRequest, type: :model, connect_to_mediaflux: true do
  let(:approver) { FactoryBot.create :sysadmin }
  let(:session_id) { approver.mediaflux_session }
  let(:approved_project) do
    project = FactoryBot.create :approved_project
    mediaflux_id = project.save_in_mediaflux(session_id: )
    meta = ProjectMetadata.new(project: project, current_user: approver)
    data_sponsor = User.find_by(uid: project.metadata[:data_sponsor])
    project.provenance_events.create(event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE, event_person: data_sponsor.uid, event_details: "Requested by #{data_sponsor.display_name_safe}")
    meta.approve_project(params: { mediaflux_id:, project_directory_prefix: "tigerns/test", project_directory: "approved_project",
                                   storage_capacity: { size: { requested: 200, approved: 100 }, unit: { requested: "PB", approved: "TB" } },
                                   storage_performance_expectations: { requested: "Standard", approved: "Fast" } })
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
    it "updates the submission" do
      approve_request = described_class.new(session_token: session_id, project: approved_project)
      approve_request.resolve
      req = Mediaflux::Http::AssetMetadataRequest.new(session_token: session_id, id: approved_project.mediaflux_id)
      metadata  = req.metadata
      expect(req.error?).to be_falsey
      approval = approved_project.provenance_events.find_by(event_type: ProvenanceEvent::APPROVAL_EVENT_TYPE)
      expect(metadata[:submission][:approved_by]).to eq(approval.event_person)
      submission = approved_project.provenance_events.find_by(event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE)
      expect(metadata[:submission][:requested_by]).to eq(submission.event_person)
    end
  end
end
