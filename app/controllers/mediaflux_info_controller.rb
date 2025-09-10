# frozen_string_literal: true
class MediafluxInfoController < ApplicationController
  # GET /mediaflux_infos or /mediaflux_infos.json
  def index
    version_request = Mediaflux::VersionRequest.new(session_token: current_user.mediaflux_session)
    @mf_version = version_request.version
    @mediaflux_roles = User.mediaflux_roles(user: current_user)
    @sysadmin = current_user.sysadmin
    @developer = current_user.developer
    respond_to do |format|
      format.html
      format.json { render json: @mf_version }
    end
  end
end
