# frozen_string_literal: true
class ProjectCreate < Dry::Operation
  class ProjectCreateError < StandardError; end

  # TODO: Remove the optional project parameter once https://github.com/pulibrary/tigerdata-app/issues/1707
  # has been completed. In practice the project is always created from the request.
  def call(request:, approver:, project: nil)
    if project.nil?
      project = step create_project_from_request(request)
    end
    mediaflux_id = step persist_in_mediaflux(project, approver)
    step update_project_with_mediaflux_info(mediaflux_id:, project:)
    step persist_users_in_mediaflux(project, approver)
    step activate_project(project, approver)
  end

  private
    def create_project_from_request(request)
      # Create the project in the Rails database
      project_metadata_json = RequestProjectMetadata.convert(request)
      # Link the request to the project
      request.project_id = project.id
      project = Project.create!({ metadata_json: project_metadata_json })
      project.draft_doi
      project.save!

      # Return Success(attrs) or Failure(error)
      Success project
    rescue => ex
      Failure("Error creating the project: #{ex}")
    end

    def persist_in_mediaflux(project, current_user)
      # Create the project in Mediaflux
      mediaflux_request = Mediaflux::ProjectCreateServiceRequest.new(session_token: current_user.mediaflux_session, project: project)
      mediaflux_request.resolve

      mediaflux_id = mediaflux_request.mediaflux_id

      if mediaflux_id.to_i == 0
        debug_output = "Error saving project #{project.id} to Mediaflux: #{mediaflux_request.response_error}. Debug output: #{mediaflux_request.debug_output}"
        Rails.logger.error debug_output
        Failure debug_output
      else
        ProvenanceEvent.generate_approval_events(project: project, user: current_user, debug_output: mediaflux_request.debug_output.to_s)
        Success(mediaflux_id)
      end
    rescue => ex
      Failure("Error saving project #{project.id} to Mediaflux: #{ex}")
    end

    def update_project_with_mediaflux_info(mediaflux_id:, project:)
      project.mediaflux_id = mediaflux_id
      project.metadata_model.status = Project::APPROVED_STATUS
      project.save!
      Success(project)
    rescue => ex
      # TODO: It was saved in mediaflux, so maybe a retry here?  I don't want to destroy the project
      Failure("Setting the mediaflux id the project(#{project.id}) : #{ex}")
    end

    def persist_users_in_mediaflux(project, current_user)
      # Do nothing if there are no users to persist
      return Success(project) if (project.metadata_model.ro_users + project.metadata_model.rw_users).empty?

      # Add the data users to the project in Mediaflux
      add_users_request = Mediaflux::ProjectUserAddRequest.new(session_token: current_user.mediaflux_session, project: project)
      add_users_request.resolve

      if add_users_request.error?
        # TODO: what should we do with the project in this case?  It got all the way to mediaflux, but the users were not added
        Failure("Error adding users to mediaflux project #{project.mediaflux_id} #{add_users_request.response_error}")
      else
        user_debug = add_users_request.debug_output.to_s
        Rails.logger.debug { "Project #{project.id} users have been added to MediaFlux: #{user_debug}" }
        Success project
      end
    rescue => ex
      Failure("Exception adding users to mediaflux project #{project.mediaflux_id}: #{ex}")
    end

    def activate_project(project, approver)
      project.activate(current_user: approver)
      Success(project)
    rescue => ex
      Failure("Error activate project #{project.id}: #{ex}")
    end
end
