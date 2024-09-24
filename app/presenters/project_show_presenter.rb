# frozen_string_literal: true
class ProjectShowPresenter
  delegate "id", "in_mediaflux?", "mediaflux_id", "metadata", "metadata_model", "pending?", "project_directory", "status", "title", to: :project

  attr_reader :project

  def initialize(project)
    @project = project
  end
end
