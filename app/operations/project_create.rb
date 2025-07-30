# frozen_string_literal: true
class CreateProject < Dry::Operation
  def call(request)
    project = step create_project_from_request(request)
    mediaflux_id = step persist_in_mediaflux(project)
    step persist_users_in_mediaflux(project, mediaflux_id)
    Success project
  end

  private

    def create_project_from_request(_request)
      project_metadata_json = RequestProjectMetadata.convert(self)
      # Create the project in the Rails database
      project = Project.create!({ metadata_json: project_metadata_json })
      project.draft_doi
      project.save!
      Success project
      # Return Success(attrs) or Failure(error)
    end

    def persist_in_mediaflux(project)
      # Create the project in Mediaflux
      request = Mediaflux::ProjectCreateServiceRequest.new(session_token: current_user.mediaflux_session, project: self)
      request.resolve

      if request.mediaflux_id.to_i == 0
        raise ProjectCreateError, "Error saving project #{id} to Mediaflux: #{request.response_error}. Debug output: #{request.debug_output}"
      end

      project.mediaflux_id = request.mediaflux_id
      project.metadata_model.status = Project::APPROVED_STATUS
      project.save!
      Success project.mediaflux_id
      # Return Success(user) or Failure(error)
    end

    def persist_users_in_mediaflux(_project, _mediaflux_id)
      # Add the data users to the project in Mediaflux
      add_users_request = Mediaflux::ProjectUserAddRequest.new(session_token: current_user.mediaflux_session, project: self)
      add_users_request.resolve

      user_debug = add_users_request.debug_output.to_s
      Rails.logger.error "Project #{id} users have been added to MediaFlux: #{user_debug}"
      Success true
      # Return Success(true) or Failure(error)
    end
end
