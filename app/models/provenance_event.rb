# frozen_string_literal: true
class ProvenanceEvent < ApplicationRecord
  SUBMISSION_EVENT_TYPE = "Submission"
  APPROVAL_EVENT_TYPE = "Approved"
  ACTIVE_EVENT_TYPE = "Active"
  STATUS_UPDATE_EVENT_TYPE = "Status Update"
  belongs_to :project
end
