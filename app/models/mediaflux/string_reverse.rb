# frozen_string_literal: true
module Mediaflux
  class StringReverse < Request
    # This is only here to prove that we can use a mediaflux service that is provided by
    # a java plugin.

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    def initialize(string:, session_token:)
      super(session_token: session_token)
      @string = string
    end

    # Specifies the Mediaflux service to use when querying Mediaflux.
    # @return [String]
    def self.service
      "tigerdata.trivial :string #{@string}"
    end
  end
end
