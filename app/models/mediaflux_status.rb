# frozen_string_literal: true

class MediafluxStatus < HealthMonitor::Providers::Base
  def check!
    # Notice that we check Mediaflux status using our TigerData account
    # (rather than the "logged in" user since there is not always a logged
    # in user for the health check)
    Rails.cache.fetch("mediaflux_health_session", expires_in: 5.minutes) do
      logon_request = Mediaflux::LogonRequest.new
      session_token = logon_request.session_token
      raise logon_request.response_error[:message] if logon_request.error?

      Mediaflux::LogoutRequest.new(session_token:)

      session_token
    rescue StandardError => e
      Rails.logger.error("Mediaflux error #{e.message}")
      raise StandardError, "Mediaflux error: Go to the server logs for details"
    end
  end
end
