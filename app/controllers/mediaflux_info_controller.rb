# frozen_string_literal: true
class MediafluxInfoController < ApplicationController
  # GET /mediaflux_infos or /mediaflux_infos.json
  def index
    version_request = Mediaflux::VersionRequest.new(session_token: current_user.mediaflux_session)
    @mf_version = version_request.version
    @current_user_mediaflux_roles = current_user.current_user_mediaflux_roles(session_token: current_user.mediaflux_session)
    respond_to do |format|
      format.html
      format.json { render json: @mf_version }
    end
  end
end
