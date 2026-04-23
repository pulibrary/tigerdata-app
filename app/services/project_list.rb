class ProjectList
  attr_reader :user, :project, :aql_query

  def initialize(user, aql_query = "xpath(tigerdata:project/ProjectID) has value")
    @user = user
    @aql_query = aql_query
  end

  def all_projects
    @all_projects ||= begin
                        request = Mediaflux::ProjectListRequest.new(session_token: user.mediaflux_session, aql_query:)
                        request.resolve
                        if request.error?
                          Rails.logger.error("Error fetching project list for user #{user&.uid}: #{request.response_error[:message]}")
                          Honeybadger.notify("Error fetching project list for user #{user&.uid}: #{request.response_error[:message]}")
                          []
                        else
                          request.results.sort_by { |project| project[:title] }
                        end
                      end
    end
end