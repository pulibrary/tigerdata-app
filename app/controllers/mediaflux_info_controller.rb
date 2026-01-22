# frozen_string_literal: true
class MediafluxInfoController < ApplicationController
  # GET /mediaflux_infos or /mediaflux_infos.json
  def index
    @mf_version = mediaflux_version_info
    @mediaflux_roles = User.mediaflux_roles(user: current_user)
    @sysadmin = current_user.sysadmin
    @developer = current_user.developer
    @java_plugin_status = java_plugin_check
    @java_plugin_version = java_plugin_version
    respond_to do |format|
      format.html
      format.json { render json: @mf_version }
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

    def java_plugin_version
      describe_request = Mediaflux::PackageDescribeRequest.new(package_name: "tigerdata-plugin", session_token: current_user.mediaflux_session)
      describe_request.resolve
      if describe_request.error?
        "Not available (see log for details)"
      else
        describe_request.describe[:version]
      end
    rescue => ex
      Rails.logger.error("Cannot determine version information for the Java plugin: #{ex.message}")
      "Not available (see log for details)"
    end

    def mediaflux_version_info
      # Notice that we use the system user (instead of the current user) in this request to Mediaflux
      # because the average user does not have access to execute server.version.
      version_request = Mediaflux::VersionRequest.new(session_token: current_user.mediaflux_session)
      version_request.resolve
      raise version_request.response_error[:message] if version_request.error?
      version_request.version
    rescue => ex
      Rails.logger.error("Error fetching Mediaflux version: #{ex.message}")
      { vendor: "N/A", version: "N/A" }
    end
end
