# frozen_string_literal: true
class SessionInfoController < ApplicationController
  # GET /session-info
  def index
    @mediaflux_info = mediaflux_info
    @mediaflux_roles = User.mediaflux_roles(user: current_user)
    @sysadmin = current_user.sysadmin
    @developer = current_user.developer
    @java_plugin_status = java_plugin_check
    respond_to do |format|
      format.html
      format.json { render json: @mediaflux_info }
    end
  end

  private

    def java_plugin_check
      trivial_attempt = Mediaflux::StringReverse.new(string: "Hello, Mediaflux!", session_token: current_user.mediaflux_session)
      trivial_attempt.resolve
      trivial_attempt.response_body
    rescue => ex
      Rails.logger.error("Java plugin not working: #{ex.message}")
      "Not working: #{ex.message}"
    end

    def mediaflux_info
      # Notice that we use the system user (instead of the current user) in this request to Mediaflux
      # because the average user does not have access to execute server.version.
      describe_request = Mediaflux::TigerdataDescribeRequest.new(session_token: current_user.mediaflux_session)
      describe_request.resolve
      raise describe_request.response_error[:message] if describe_request.error?
      describe_request.server_values
    rescue => ex
      Rails.logger.error("Error fetching server information: #{ex.message}")
      { uuid: "N/A" }
    end
end
