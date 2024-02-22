# frozen_string_literal: true

class ProjectJobService
  def initialize(project:)
    @project = project
  end

  def list_contents_job(user:)
    ListProjectContentsJob.perform_now(user_id: user.id, project_title: @project.title)
  end
end
