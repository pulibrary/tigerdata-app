# frozen_string_literal: true

class ProjectJobService
  def initialize(project:)
    @project = project
  end

  def list_contents_job(user:)
    job = FileInventoryJob.perform_later(user_id: user.id, project_id: @project.id)
    # Log the job id and the Sidekiq JID in case we need to troubleshoot the job
    # https://github.com/sidekiq/sidekiq/wiki/Active-Job#job-id
    Rails.logger.info("Job scheduled, job id: #{job.job_id}, (Sidekiq JID: #{job.provider_job_id || 'nil'})")
  end
end
