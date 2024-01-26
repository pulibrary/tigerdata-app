# frozen_string_literal: true
class TestAssetGenerator
  attr_reader :levels, :base_name, :file_count_per_directory
  def initialize(user:, project_id:, levels: 5, directory_per_level: 100, file_count_per_directory: 1000)
    @user = user
    @project = Project.find(project_id)
    @levels = levels
    @directory_per_level = directory_per_level
    @file_count_per_directory = file_count_per_directory
    @base_name = @project.directory
  end

  def generate
    generate_level(@project.mediaflux_id, levels)
  end

  private
    def generate_level(parent_id, level)
      if level > 1
        collection = Mediaflux::Http::CreateAssetRequest.new(session_token: @user.mediaflux_session, name: "#{base_name}-#{level}", pid: parent_id)
        generate_level(collection.id, level-1)
      end
      Mediaflux::Http::TestAssetCreateRequest.new(session_token: @user.mediaflux_session, parent_id: parent_id, count: file_count_per_directory).resolve
    end
end
