# frozen_string_literal: true
class ProjectFileInventory
  def initialize(project:, session_id:, filename:)
    @project = project
    @session_id = session_id
    @filename = filename
    @paths_queue = []
    @log_prefix = "file_list_to_file_fast #{session_id[0..7]} #{project.mediaflux_id}"
    @io_file = nil
  end

  # Generate the file with the file inventory
  def generate()
    start_time = Time.zone.now
    log_elapsed(start_time, "STARTED")
    @io_file = File.open(@filename, "a")

    # Add the root of the project to the queue...
    add_path_to_queue(collection_id: @project.mediaflux_id, path_prefix: @project.project_directory)

    # ... and start processing (more paths might be added during `process_path`)
    loop do
      next_path = @paths_queue.pop()
      break if next_path.nil?
      process_path(collection_id: next_path[:collection_id], path_prefix: next_path[:path_prefix])
    end
  ensure
    @io_file.close
    log_elapsed(start_time, "ENDED")
  end

  private

    def add_path_to_queue(collection_id:, path_prefix:)
      @paths_queue << {collection_id:, path_prefix:}
    end

    # Fetches the files for the given collection_id (which represents a path),
    # outputs the files to the `io_file`, and queues up any other children paths
    # that we might need to process.
    def process_path(collection_id:, path_prefix:)

      # Create an interator for this path
      # Notice that we do NOT include the path in the results because it is too expensive to retrieve
      # it from Mediaflux (see https://github.com/pulibrary/tigerdata-app/issues/1344 for details)
      query_req = Mediaflux::QueryRequest.new(session_token: @session_id, collection: collection_id, deep_search: false, include_path: false)
      iterator_id = query_req.result

      # ...and query the iterator for the results
      loop do
        start_time = Time.zone.now
        iterator_req = Mediaflux::IteratorRequest.new(session_token: @session_id, iterator: iterator_id, size: 1000)
        log_elapsed(start_time, "iterated over path #{path_prefix}")

        if iterator_req.error?
          raise "Error processing collection #{collection_id}: #{iterator_req.response_error[:message]}"
        end

        # ...process the files in the iterator
        csv_lines = []
        iterator_response = iterator_req.result
        iterator_response[:files].each do |file|
          # Calculate the path for this file. This is necessary because we are NOT fetching
          # the path from Mediaflux (see `include_path: false` above).
          file.path = "#{path_prefix}/#{file.name}"
          if file.collection == true
            # add the folder to the queue
            add_path_to_queue(collection_id: file.id, path_prefix: file.path)
          else
            # collection the file information
            csv_lines << "#{file.id}, #{file.path_only}, #{file.name}, #{file.collection}, #{file.last_modified}, #{file.size}"
          end
        end

        # write the lines for this iteration the CSV file
        if csv_lines.count > 0
          @io_file.write(csv_lines.join("\r\n") + "\r\n")
        end

        break if iterator_response[:complete]
      end

    end

    def log_elapsed(start_time, message)
      elapsed_time = Time.zone.now - start_time
      timing_info = "#{format('%.2f', elapsed_time)} s"
      Rails.logger.info "#{@log_prefix}: #{message}, #{timing_info}"
    end
end