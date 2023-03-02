# frozen_string_literal: true
class Project < ApplicationRecord
  has_many :project_user_roles, dependent: :restrict_with_exception

  def name
    data["name"]
  end
end
