# frozen_string_literal: true

class ProjectQuotaRefresh < Dry::Operation
  class ProjectCreateError < StandardError; end

  def call(current_user:, project_metadata:)
    quota_info = step load_mediaflux_quota(current_user:, mediaflux_id: project_metadata.mediaflux_id)
    step update_project_with_quota_info(quota_info:, project_metadata:)
  end

  private

  def load_mediaflux_quota(current_user:, mediaflux_id:)
    quota_req = Mediaflux::ProjectQuotaRequest.new(session_token: current_user.mediaflux_session, asset_id: mediaflux_id)
    if quota_req.error?
      Failure("Error gathering quota information from mediaflux for project #{mediaflux_id} on behalf of #{current_user.uid}. #{quota_req.response_error}")
    else
      Success(quota_req.quota)
    end
  rescue StandardError => e
    Failure("Error gathering quota information from mediaflux for project #{mediaflux_id} on behalf of #{current_user.uid}. #{e}")
  end

  def update_project_with_quota_info(project_metadata:, quota_info:)
    project_metadata.update_quota_breakdown(quota_info)
    Success(quota_info)
  rescue StandardError => e
    # All other errors will just be returned as failures
    Failure("Error updating project #{project_metadata.id} with quota information #{quota_info.to_json}: #{e}")
  end
end
