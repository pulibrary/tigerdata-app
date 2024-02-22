# frozen_string_literal: true

class UserJob < ApplicationRecord
  class << self
    def datestamp_format
      "%Y-%m-%dT%H:%M:%S%:z"
    end

    def format_datestamp(value)
      return if value.nil?

      localized = value.localtime
      formatted = localized.strftime(datestamp_format)
      formatted
    end
  end

  def title
    "File Inventory for \"#{project_title}\""
  end

  def description
    "Requested #{created_datestamp}"
  end

  def completed_at
    self.class.format_datestamp(super)
  end

  def completion
    "Completed #{completed_at}"
  end

  private

    def created_datestamp
      self.class.format_datestamp(created_at)
    end
end
