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
    "Requested #{created_at}"
  end

  def completed_at
    self.class.format_datestamp(super)
  end

  def completion
    "Completed #{completed_at}"
  end

  def complete?
    completed_at != nil
  end

  def self.create_and_link_to_user(job_id:, user:, job_title:)
    user_job = UserJob.where(job_id: job_id).first
    if user_job.nil?
      user_job = UserJob.create(job_id: job_id, project_title: job_title)
      user.user_jobs << user_job
      user.save!
    end
    user_job
  end

  private

    def created_datestamp
      self.class.format_datestamp(created_at)
    end
end
