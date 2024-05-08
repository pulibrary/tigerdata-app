# frozen_string_literal: true
class TestAssetGenerator
  attr_reader :levels, :base_name, :file_count_per_directory, :directory_per_level, :mediaflux_session
  def initialize(user:, project_id:, levels: 5, directory_per_level: 100, file_count_per_directory: 1000)
    @user = user
    @project = Project.find(project_id)
    @levels = levels
    @directory_per_level = directory_per_level
    @file_count_per_directory = file_count_per_directory
    @base_name = @project.project_directory_short
    @mediaflux_session = @user.mediaflux_session
  end

  def generate
    generate_level(@project.mediaflux_id, levels)
  end

  private

    def generate_level(parent_id, level)
      return if level == 0
      collection = Mediaflux::Http::AssetCreateRequest.new(session_token: mediaflux_session, name: "#{base_name}-#{level}", pid: parent_id)
      collection_id = collection.id  # resolves the request and extracts the id
      generate_directory(collection_id, directory_per_level)
      generate_level(collection_id, level - 1)
    end

    def generate_directory(parent_id, directory_count)
      return if directory_count == 0
      name_extention = (0...10).map { ("a".."z").to_a[rand(26)] }.join
      dir_collection = Mediaflux::Http::AssetCreateRequest.new(session_token: mediaflux_session, name: "#{base_name}-#{parent_id}-#{name_extention}", pid: parent_id)
      dir_collection_id = dir_collection.id
      raise dir_collection.response_error.to_s if dir_collection_id.blank?
      Mediaflux::Http::TestAssetCreateRequest.new(session_token: mediaflux_session, parent_id: dir_collection_id, count: file_count_per_directory).resolve
      generate_directory(parent_id, directory_count - 1)
    end
end
