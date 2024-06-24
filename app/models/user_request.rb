# frozen_string_literal: true
class UserRequest < ApplicationRecord
  belongs_to :user
  belongs_to :project

  PENDING = "pending"
  COMPLETED = "completed"
  STALE = "stale"

  validates :state, inclusion: { in: [PENDING, COMPLETED, STALE] }
end
