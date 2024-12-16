# frozen_string_literal: true
class SystemUser
  def self.mediaflux_session
    Rails.cache.fetch("mediaflux_session", expires_in: 10.minutes) do
      logon_request = Mediaflux::LogonRequest.new
      if logon_request.error?
        raise Mediaflux::SessionError, "System logon was invalid! #{logon_request.response_error}"
      end
      logon_request.session_token
    end
  end
end
