# frozen_string_literal: true

require "json-schema"

class SchemaValidator < ActiveModel::Validator
  def validate(record)
    # TODO: Pull this into a stand-alone file if we keep it.
    schema = {
      "type" => "object",
      "required" => ["name"],
      "properties" => {
        "name" => { "type" => "string" }
      }
    }
    errors = JSON::Validator.fully_validate(schema, record.data)
    errors.each do |error|
      record.errors.add(:data, message: error)
    end
  end
end

class Project < ApplicationRecord
  has_many :project_user_roles, dependent: :restrict_with_exception
  validates_with ::SchemaValidator

  after_initialize :set_default_values
  def set_default_values
    self.data ||= {}
  end

  def name
    data["name"]
  end

  def name=(new_name)
    data["name"] = new_name
  end
end
