class ProjectSearch < Dry::Operation
    def call(search_string:, requestor:, field_name: "Title")
        verified_search_string = step verify_search_string(search_string)
        result_ids = step query_mediaflux(search_string: verified_search_string, requestor:, field_name:)
        step convert_results(result_ids)
    end

    private

    def verify_search_string(search_string)
        # An empty search does not make sense
        if search_string.blank?
            Failure("Search String cannot be empty")
        # Assuming there may be more verifications in the future
        else
            Success(search_string)
        end
    end

    def query_mediaflux(search_string:, requestor:, field_name:)
      query = mediaflux_query(search_string:, requestor:, field_name:)
      if query.error?
        Failure("Error querying mediaflux: #{query.response_error[:message]}")
      else
        result_ids = query.result_items.map{|result| result[:id]}
        Success(result_ids)
      end
    end

    def mediaflux_query(search_string:, requestor:, field_name:)
      aql_query = "xpath(tigerdata:project/#{field_name}) matches ignore-case '#{search_string}'"
      Mediaflux::QueryRequest.new(session_token: requestor.mediaflux_session, aql_query: , iterator: false )
    end


    def convert_results(result_ids)
      projects_not_found = []
      projects = []
      result_ids.map do |mediaflux_id|
        project = Project.find_by(mediaflux_id: )
        if project.blank?
          projects_not_found << mediaflux_id
        else
          projects << project
        end
      end
      if projects_not_found.count > 0
        Rails.logger.error("The following Mediaflux Projects were not found in the Rails database: #{projects_not_found.join(', ')}")
        Honeybadger.notify("The following Mediaflux Projects were not found in the Rails database: #{projects_not_found.join(', ')}")
      end
      Success(projects)
    end
end