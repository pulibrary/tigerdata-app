# frozen_string_literal: true
class ListProjectContentsJob < ApplicationJob
  def perform(args)
    project = Project.find(args[:project_id])
    user = User.find(args[:user_id])
    filename = export_filename(project: project, user: user)
    project.file_list_to_file(session_id: mediaflux_session, filename: filename)
    mark_user_job_as_complete(project: project, user: user)
  end

  private

    def mediaflux_session
      logon_request = Mediaflux::Http::LogonRequest.new
      logon_request.resolve
      logon_request.session_token
    end

    # TODO: This only works with one server. In a multi-server environment
    # there is no guarantee that the client will be able to fetch the file
    # since requests could go to any of the many servers.
    # See https://github.com/pulibrary/tiger-data-app/issues/523
    def export_filename(project:, user:)
      timestamp = Time.now.getlocal.strftime("%Y-%m-%dT%H-%M")
      netid = user.uid
      "#{Dir.pwd}/public/#{job_id}.csv"
    end

    def mark_user_job_as_complete(project:, user:)
      user_job = UserJob.where(job_id:job_id).first
      if user_job == nil
        user_job = UserJob.create(job_id: job_id, project_title: project.title)
        user.user_jobs << user_job
        user.save!
      end
      user_job.complete = true
      user_job.save!
    end
end
