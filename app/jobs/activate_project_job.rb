class ActivateProjectJob < ApplicationJob
  queue_as :default

  def perform(user:, project_id:)
    project = Project.find(project_id)
    raise "Invalid project id #{project_id} for job #{job_id}" if project.nil?

    collection_id = project.metadata_json["project_id"]

    # ACTIVATE THE PROJECT IF THE DOI IN RAILS AND MF MATCH
    ProjectMetadata.activate_project(collection_id: collection_id, session_token: mediaflux_session)
    # SEND AN EMAIL TO THE SYSADMIN IF THE DOIs DO NOT MATCH
    project.reload
    activation_failure_msg = "Project with #{collection_id} failed to activate due to mismatched DOI's between rails and mediaflux"
    if project.status != ACTIVE_STATUS
      #send email

      
      # SEND A NOTI TO HONEYBADGER IF THE DOIs DO NOT MATCH
      honeybadger_context = {
        project_id: project.id,
        project_metadata: project.metadata
      }
      Honeybadger.notify(activation_failure_msg, context: honeybadger_context)
    end

      mark_user_job_as_complete(project: project, user: user)
  end

  private
    def mediaflux_session
      logon_request = Mediaflux::Http::LogonRequest.new
      logon_request.session_token
    end

    def mark_user_job_as_complete(project:, user:)
      user_job = UserJob.create_and_link_to_user(job_id: job_id, user: user, job_title: "Project Activation for #{project.title}")
      user_job.completed_at = Time.current.in_time_zone("America/New_York").iso8601
      user_job.save!
      user_job.reload
    end
end
