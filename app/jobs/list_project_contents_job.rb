# frozen_string_literal: true
class ListProjectContentsJob < ApplicationJob
  def perform(args)
    project = Project.find(args[:project_id])
    user = User.find(args[:user_id])
    filename = export_filename(project, user)
    project.file_list_to_file(session_id: mediaflux_session, filename: filename)
  end

  private

    def mediaflux_session
      logon_request = Mediaflux::Http::LogonRequest.new
      logon_request.resolve
      logon_request.session_token
    end

    def export_filename(project, user)
      timestamp = Time.now.getlocal.strftime("%Y-%m-%dT%H-%M")
      netid = user.uid
      # TODO: where should we store these files
      "/Users/correah/src/tiger-data-app/#{netid}-#{project.directory}-#{timestamp}.csv"
    end
end
