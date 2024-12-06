# frozen_string_literal: true
class ProjectShowPresenter
  delegate "id", "in_mediaflux?", "mediaflux_id", "pending?", "status", "title", to: :project
  delegate "description", "project_id", "storage_capacity", "storage_performance_expectations", "project_purpose", to: :project_metadata

  attr_reader :project, :project_metadata

  def initialize(project)
    @project = project
    @project_metadata = @project.metadata_model
  end

  def created
    @project.created_at.strftime("%b %e, %Y %l:%M %p")
  end 

  def updated 
    @project.updated_at.strftime("%b %e, %Y %l:%M %p")
  end 

  def data_sponsor 
    User.find_by(uid: @project.metadata["data_sponsor"]).display_name_safe
  end 

  def data_manager 
    User.find_by(uid: @project.metadata["data_manager"]).display_name_safe
  end 

  # used to hide the project root that is not visible to the end user
  def project_directory
    project.project_directory.gsub(Mediaflux::Connection.hidden_root, "")
  end
end
