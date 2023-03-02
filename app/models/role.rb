# frozen_string_literal: true
class Role < ApplicationRecord
    has_many :allowed_roles
    has_many :project_user_roles
end
