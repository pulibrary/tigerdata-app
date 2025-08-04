# frozen_string_literal: true
class ProjectCreate < Dry::Operation
  class ProjectCreateError < StandardError; end

  def call(request:, approver:)
    project = step create_project_from_request(request)
    step persist_in_mediaflux(project, approver)
    step persist_users_in_mediaflux(project, approver)
    Success project
  end

  private

    def create_project_from_request(request)
      # Create the project in the Rails database
      project_metadata_json = RequestProjectMetadata.convert(request)
      project = Project.create!({ metadata_json: project_metadata_json })
      project.draft_doi
      project.save!

      # Return Success(attrs) or Failure(error)
      Success project
    end

    # rubocop:disable Metrics/MethodLength
    def persist_in_mediaflux(project, current_user)
      # Create the project in Mediaflux
      request = Mediaflux::ProjectCreateServiceRequest.new(session_token: current_user.mediaflux_session, project: project)
      request.resolve

      if request.mediaflux_id.to_i == 0
        raise ProjectCreateError, "Error saving project #{project.id} to Mediaflux: #{request.response_error}. Debug output: #{request.debug_output}"
      end
      project.mediaflux_id = request.mediaflux_id
      project.metadata_model.status = Project::APPROVED_STATUS
      project.save!

      debug_output = if request.mediaflux_id == 0
                       "Error saving project #{project.id} to Mediaflux: #{request.response_error}. Debug output: #{request.debug_output}"
                     else
                       request.debug_output.to_s
                     end
      Rails.logger.error debug_output

      ProvenanceEvent.generate_approval_events(project: project, user: current_user, debug_output: debug_output)

      Success project.mediaflux_id
      # Return Success(user) or Failure(error)
    end
    # rubocop:enable Metrics/MethodLength

    def persist_users_in_mediaflux(project, current_user)
      # Add the data users to the project in Mediaflux
      add_users_request = Mediaflux::ProjectUserAddRequest.new(session_token: current_user.mediaflux_session, project: project)
      add_users_request.resolve

      user_debug = add_users_request.debug_output.to_s
      Rails.logger.debug { "Project #{project.id} users have been added to MediaFlux: #{user_debug}" }

      Success true
      # Return Success(true) or Failure(error)
    end
end
