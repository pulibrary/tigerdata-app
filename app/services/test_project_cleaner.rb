# frozen_string_literal: true
class TestProjectCleaner
  def initialize(path = "/princeton/tigerdata/RDSS/")
    @path = path
  end

  def clean
    test_projects = Project.where("metadata_json->> 'project_directory' like ?", "#{@path}%") # Implementation for cleaning project at @path
    test_projects.map(&:destroy)
  end

  def reload
    clean
    ProjectImport.run_with_report(mediaflux_session: SystemUser.mediaflux_session).sort
  end
end
