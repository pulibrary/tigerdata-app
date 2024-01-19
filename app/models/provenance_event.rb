# frozen_string_literal: true
class ProvenanceEvent < ApplicationRecord
  SUBMISSION_EVENT_TYPE = "Submission"
  STATUS_UPDATE_EVENT_TYPE = "Status Update"
  belongs_to :project
end
