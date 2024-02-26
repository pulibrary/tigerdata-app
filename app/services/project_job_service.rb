# frozen_string_literal: true

class ProjectJobService
  def initialize(project:)
    @project = project
  end

  def list_contents_job(user:)
    job = ListProjectContentsJob.perform_later(user_id: user.id, project_id: @project.id)
    UserJob.create_and_link_to_user(job_id: job.job_id, user: user, job_title: "File list for #{@project.title}")
  end
end
