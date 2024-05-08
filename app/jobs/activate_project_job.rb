class ActivateProjectJob < ApplicationJob
  queue_as :default

  def perform(user:, project_id:)
    project = Project.find(project_id)
    raise "Invalid project id #{project_id} for job #{job_id}" if project.nil?
    collection_id = project.metadata_json["project_id"]
    project_metadata = project.metadata_model

    # ACTIVATE THE PROJECT IF THE DOI IN RAILS AND MF MATCH
    project_metadata.activate_project(collection_id: collection_id, current_user: user)
    
    project.reload
    return unless project.status != Project::ACTIVE_STATUS #CHECK IF PROJECT ACTIVATION WAS SUCCESSFUL
    activation_failure_msg = "Project with #{collection_id} failed to activate due to mismatched DOI's between rails and mediaflux"
    
    #SEND EMAIL
    mailer = TigerdataMailer.with(project_id: project.id, user:, activation_failure_msg:)
    message_delivery = mailer.project_activation
    message_delivery.deliver_later

    # NOTIFY HONEYBADGER
    honeybadger_context = {
      project_id: project.id,
      project_metadata: project.metadata
    }
    Honeybadger.notify(activation_failure_msg, context: honeybadger_context)

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
