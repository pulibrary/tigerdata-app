# frozen_string_literal: true
class CreateProject < Dry::Operation
  def call(request)
    project = step create_project_from_request(request)
    mediaflux_id = step persist_in_mediaflux(project)
    step persist_users_in_mediaflux(project, mediaflux_id)
    Success project
  end

  private

    def create_project_from_request(request)
      project_metadata_json = RequestProjectMetadata.convert(self)
      # Create the project in the Rails database
      project = Project.create!({ metadata_json: project_metadata_json })
      project.draft_doi
      project.save!
      Success project
      # Return Success(attrs) or Failure(error)
    end

    def persist_in_mediaflux(project)
      result = create_in_mediaflux(project:, approver:)
      # Return Success(user) or Failure(error)
    end

    def persist_users_in_mediaflux(project, mediaflux_id)
      Success true
      # Return Success(true) or Failure(error)
    end
end
