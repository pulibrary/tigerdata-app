# frozen_string_literal: true
class ProvenanceEvent < ApplicationRecord
  SUBMISSION_EVENT_TYPE = "Submission"
  APPROVAL_EVENT_TYPE = "Approved"
  ACTIVE_EVENT_TYPE = "Active"
  STATUS_UPDATE_EVENT_TYPE = "Status Update"
  DEBUG_OUTPUT_TYPE = "Debug Output"
  belongs_to :project

  def self.generate_submission_events(project:, user:)
    project.provenance_events.create(
      event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE,
      event_person: user.uid,
      event_details: "Requested by #{user.display_name_safe}"
    )
    project.provenance_events.create(
      event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE,
      event_person: user.uid,
      event_details: "The Status of this project has been set to pending"
    )
  end

  def self.generate_approval_events(project:, user:, debug_output: nil)
    project.provenance_events.create(
      event_type: ProvenanceEvent::APPROVAL_EVENT_TYPE,
      event_person: user.uid,
      event_details: "Approved by #{user.display_name_safe}",
      event_note: project.metadata_model.approval_note
    )
    project.provenance_events.create(
      event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE,
      event_person: user.uid,
      event_details: "The Status of this project has been set to approved"
    )
    unless debug_output.nil?
      project.provenance_events.create(event_type: ProvenanceEvent::DEBUG_OUTPUT_TYPE, event_person: user.uid, event_details: "Debug output", event_note: debug_output)
    end
  end

  def self.generate_active_events(project:, user:)
    project.provenance_events.create(
      event_type: ProvenanceEvent::ACTIVE_EVENT_TYPE,
      event_person: user.uid,
      event_details: "Activated by Tigerdata Staff"
    )
    project.provenance_events.create(
      event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE,
      event_person: user.uid,
      event_details: "The Status of this project has been set to active"
    )
  end
end
