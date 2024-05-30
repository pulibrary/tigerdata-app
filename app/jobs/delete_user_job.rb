# frozen_string_literal: true
class DeleteUserJob < ApplicationJob
  queue_as :default

  def perform(job_id:, user_id:)
    user = User.find(user_id)
    job = UserJob.find(job_id)
    job.delete

    mark_user_job_as_complete(job_id: job_id, user: user)
  end

  private

    def mark_user_job_as_complete(job_id:, user:)
      user_job = UserJob.create_and_link_to_user(job_id: job_id, user: user, job_title: "Deleting user job with id: #{job_id}")
      user_job.completed_at = Time.current.in_time_zone("America/New_York").iso8601
      user_job.save!
      user_job.reload
    end
end
