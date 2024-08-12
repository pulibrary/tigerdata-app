# frozen_string_literal: true
class MediafluxStatus < HealthMonitor::Providers::Base
  def check!
    domain = Rails.configuration.mediaflux["api_domain"]
    user = Rails.configuration.mediaflux["api_user"]
    password = Rails.configuration.mediaflux["api_password"]
    logon_request = Mediaflux::LogonRequest.new(domain:, user:, password:)
    session_token = logon_request.session_token
    if logon_request.error?
      raise logon_request.response_error[:message]
    else
      Mediaflux::LogoutRequest.new(session_token:)
    end
  end
end
