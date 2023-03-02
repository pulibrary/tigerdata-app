# frozen_string_literal: true
class Role < ApplicationRecord
  has_many :allowed_roles, dependent: :restrict_with_exception
  has_many :project_user_roles, dependent: :restrict_with_exception
end
