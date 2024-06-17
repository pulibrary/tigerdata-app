# frozen_string_literal: true
class UserRequest < ApplicationRecord
  belongs_to :user
  belongs_to :project
end
