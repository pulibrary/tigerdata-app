# frozen_string_literal: true
class TestAssetGenerator
  def initialize(user:, project_id:, levels: 5, directory_per_level: 100, file_count_per_directory: 1000)
    @user = user
    @project = Project.find(project_id)
    @levels = levels
    @directory_per_level = directory_per_level
    @file_count_per_directory = file_count_per_directory
  end

  def generate
    Mediaflux::Http::TestAssetCreateRequest.new(session_token: @user.mediaflux_session, parent_id: @project.mediaflux_id).resolve
  end
end
