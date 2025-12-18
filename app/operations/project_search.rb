class ProjectSearch < Dry::Operation
    def call(search_string:, requestor:, field_name: "Title")
        verified_search_string = step verify_search_string(search_string)
        mf_results = step query_mediaflux(search_string: verified_search_string, requestor:, field_name:)
        step convert_results(mf_results, requestor)
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
        Success(query.results)
      end
    end

    def mediaflux_query(search_string:, requestor:, field_name:)
      aql_query = "xpath(tigerdata:project/#{field_name}) matches ignore-case '#{search_string}'"
      request = Mediaflux::ProjectListRequest.new(session_token: requestor.mediaflux_session, aql_query:)
    end


    def convert_results(mf_results, requestor)
      presenters = mf_results.map{ |result| ProjectDashboardPresenter.new( result, requestor)}
      Success(presenters.reject{|presenter| presenter.project.blank?})
    end
end