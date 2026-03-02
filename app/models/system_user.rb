# frozen_string_literal: true
class SystemUser
  class << self
    def mediaflux_session
      Rails.cache.fetch("mediaflux_session", expires_in: 10.minutes) do
        logon_request = Mediaflux::LogonRequest.new
        if logon_request.error?
          raise Mediaflux::SessionError, "System logon was invalid! #{logon_request.response_error}"
        end
        logon_request.session_token
      end
    rescue EOFError => ex
      # Retry EOFErrors a few times
      if eof_error_handler
        Rails.logger.error "EOFError detected when attempting system logon. Details: #{ex.message}, retrying..."
        Honeybadger.notify "EOFError detected when attempting system logon. Details: #{ex.message}, retrying..."
        retry
      else
        raise Mediaflux::SessionError, "System logon failed due to repeated EOFErrors: #{ex.message}"
      end
    end

    private

      def eof_error_handler
        @retry_count ||= 0
        @retry_count += 1
        # TODO: How do we fix EOF errors?  Just retrying for now.

        @retry_count < 3 # If the session is expired we should not have to retry more than once, but let's have a little wiggle room
      end
  end
end
