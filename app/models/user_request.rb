# frozen_string_literal: true
class UserRequest < ApplicationRecord
  belongs_to :user
  belongs_to :project

  PENDING = "pending"
  COMPLETED = "completed"
  STALE = "stale"
  FAILED = "failed"

  validates :state, inclusion: { in: [PENDING, COMPLETED, STALE, FAILED] }

  def complete?
    state == COMPLETED
  end

  def failed?
    state == FAILED
  end
end
