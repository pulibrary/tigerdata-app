# frozen_string_literal: true
class MediafluxInfoController < ApplicationController
  # GET /mediaflux_infos or /mediaflux_infos.json
  def index
    @mf_version = mediaflux_version_info
    @mediaflux_roles = User.mediaflux_roles(user: current_user)
    @sysadmin = current_user.sysadmin
    @developer = current_user.developer
    respond_to do |format|
      format.html
      format.json { render json: @mf_version }
    end
  end

  private

    def mediaflux_version_info
      # Notice that we use the system user (instead of the current user) in this request to Mediaflux
      # because the average user does not have access to execute server.version.
      version_request = Mediaflux::VersionRequest.new(session_token: SystemUser.mediaflux_session)
      version_request.resolve
      raise version_request.response_error[:message] if version_request.error?
      version_request.version
    rescue => ex
      Rails.logger.error("Error fetching Mediaflux version: #{ex.message}")
      { vendor: "N/A", version: "N/A" }
    end
end
