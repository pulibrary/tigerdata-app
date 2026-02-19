# frozen_string_literal: true
class ProjectFileInventory
  def initialize(project:, session_id:, filename:)
    @project = project
    @session_id = session_id
    @filename = filename
    @paths_queue = []
  end

  def generate()
    # Add the root of the project to the queue and start processing
    add_path_to_queue(collection_id: @project.mediaflux_id, path_prefix: @project.project_directory)
    loop do
      next_path = @paths_queue.pop()
      break if next_path.nil?
      process_path(collection_id: next_path[:collection_id], path_prefix: next_path[:path_prefix])
    end
  end

  private

    def add_path_to_queue(collection_id:, path_prefix:)
      @paths_queue << {collection_id:, path_prefix:}
    end

    def process_path(collection_id:, path_prefix:)
      puts "Processing path #{path_prefix} (#{collection_id})"
      iterator_id = @project.file_explorer_setup(session_id: @session_id, path_id: collection_id)

      File.open(@filename, "a") do |file|

        loop do
          puts "loop"
          iterator_req = Mediaflux::IteratorRequest.new(session_token: @session_id, iterator: iterator_id, size: 20)
          iterator_resp = iterator_req.result
          break if iterator_req.error?

          lines = []
          byebug
          iterator_resp[:files].each do |asset|
            # Calculate and set the path for this file. This is necessary because we are
            # _on purpose_ not fetching the path from Mediaflux.
            asset.path = "#{path_prefix}/#{asset.name}"
            if asset.collection
              # Add the folder to the queue
              add_path_to_queue(collection_id: asset.id, path_prefix: asset.path)
            else
              lines << "#{asset.id}, #{asset.path_only}, #{asset.name}, #{asset.collection}, #{asset.last_modified}, #{asset.size}"
            end
          end

          if lines.count > 0
            file.write(lines.join("\r\n") + "\r\n")
          end

          break if iterator_resp[:complete]
        end

      end
    end
end