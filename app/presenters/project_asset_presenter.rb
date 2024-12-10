# frozen_string_literal: true
class ProjectShowPresenter
  delegate name, path_only, last_modified, size, to: asset

  def initialize(project, asset)
    @project = project
    @asset = asset
  end
end
