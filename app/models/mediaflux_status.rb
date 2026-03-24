# frozen_string_literal: true

# Handles Mediaflux status checks for health monitoring.
class MediafluxStatus < HealthMonitor::Providers::Base
  # Performs a health check by attempting to logon to Mediaflux.
  # @return [String] session_token if successful.
  # @raise [StandardError] if there's an error during logon or logout.
  def check!
    # Notice that we check Mediaflux status using our TigerData account
    # (rather than the "logged in" user since there is not always a logged
    # in user for the health check)
    Rails.cache.fetch("mediaflux_health_session", expires_in: 5.minutes) do
      logon_request = Mediaflux::LogonRequest.new
      session_token = logon_request.session_token
      if logon_request.error?
        raise logon_request.response_error[:message]
      else
        Mediaflux::LogoutRequest.new(session_token:)
      end
      session_token
    rescue StandardError => e
      Rails.logger.error("Mediaflux error #{e.message}")
      raise StandardError, "Mediaflux error: Go to the server logs for details"
    end
  end
end
