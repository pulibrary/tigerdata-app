# frozen_string_literal: true
class AqlQueriesController < ApplicationController
  # GET /aql_queries or /aql_queries.json
  def index
    @aql_query = params[:aql_query]
    if @aql_query.blank?
      @results = []
    else
      query = Mediaflux::QueryRequest.new(session_token: current_user.mediaflux_session, aql_query: @aql_query, iterator: false)
      if query.error?
        @results = []
        flash[:notice] = query.response_error[:message][1..250]
      else
        flash[:notice] = nil
        @results = query.result_items
      end
    end
  end
end
