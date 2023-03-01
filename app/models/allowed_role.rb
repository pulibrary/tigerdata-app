# frozen_string_literal: true
class AllowedRole < ApplicationRecord
  belongs_to :user
  belongs_to :role
end
