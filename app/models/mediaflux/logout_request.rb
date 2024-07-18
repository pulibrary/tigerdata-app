# frozen_string_literal: true
module Mediaflux
  class LogoutRequest < Request
    # Constructor
    # @param use_ssl [Boolean] determines whether or not connections to the Mediaflux server API are over the TLS/SSL
    # @param file [File] any upload file required for the POST request
    # @param session_token [String] the API token for the authenticated session
    # @param http_client [Net::HTTP] HTTP client for transmitting requests to the Mediaflux server API
    def initialize(session_token:)
      super(session_token: session_token)
    end

    # Specifies the Mediaflux service to use when logging off
    # @return [String]
    def self.service
      "system.logoff"
    end
  end
end
