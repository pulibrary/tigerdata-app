# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    return if current_user.nil?
    version_request = Mediaflux::Http::VersionRequest.new(session_token: current_user.mediaflux_session)
    @mf_version = version_request.version
    @projects = Project.sponsored_projects(@current_user.uid)
  end
end
