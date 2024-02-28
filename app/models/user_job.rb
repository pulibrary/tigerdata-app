# frozen_string_literal: true

class UserJob < ApplicationRecord

  def title
    "File Inventory for \"#{project_title}\""
  end

  def description
    "Requested #{created_datestamp}"
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
end
