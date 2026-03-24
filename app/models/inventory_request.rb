# frozen_string_literal: true

# Represents an inventory request associated with a user and project.
class InventoryRequest < ApplicationRecord
  belongs_to :user
  belongs_to :project

  PENDING = "pending"
  COMPLETED = "completed"
  STALE = "stale"
  FAILED = "failed"

  validates :state, inclusion: { in: [PENDING, COMPLETED, STALE, FAILED] }

  # Checks if the request is completed.
  # @return [Boolean] true if state is COMPLETED, false otherwise.
  def complete?
    state == COMPLETED
  end

  # Checks if the request has failed.
  # @return [Boolean] true if state is FAILED, false otherwise.
  def failed?
    state == FAILED
  end
end
