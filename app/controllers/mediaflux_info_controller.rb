# frozen_string_literal: true
class MediafluxInfoController < ApplicationController
  # GET /mediaflux_infos or /mediaflux_infos.json
  def index
    version_request = Mediaflux::Http::VersionRequest.new(session_token: current_user.mediaflux_session)
    @mf_version = version_request.version
  end
end
