class ActivateProjectJob < ApplicationJob
  queue_as :default

  def perform(user:, project_id:)
    project = Project.find(project_id)
    raise "Invalid project id #{project_id} for job #{job_id}" if project.nil?
    #The id of the project in mediaflux is the collection id, and mediaflux id is what we refer to the collection id in rails
    collection_id = project.mediaflux_id 
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
  end

  private
    def mediaflux_session
      logon_request = Mediaflux::Http::LogonRequest.new
      logon_request.session_token
    end
end
