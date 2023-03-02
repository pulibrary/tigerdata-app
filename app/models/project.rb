# frozen_string_literal: true
class Project < ApplicationRecord
    has_many :project_user_roles
end
