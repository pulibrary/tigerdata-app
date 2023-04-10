# frozen_string_literal: true
module Mediaflux
  module Http
    class SetNoteRequest < Request
      attr_reader :id, :note

      # Constructor
      # @param use_ssl [Boolean] determines whether or not connections to the Mediaflux server API are over the TLS/SSL
      # @param file [File] any upload file required for the POST request
      # @param session_token [String] the API token for the authenticated session
      # @param http_client [Net::HTTP] HTTP client for transmitting requests to the Mediaflux server API
      def initialize(session_token:, id:, note:)
        super(session_token: session_token)
        @id = id
        @note = note
      end

      # Specifies the Mediaflux service to use when setting the note on an asset
      # @return [String]
      def self.service
        "asset.set"
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.id id
              xml.meta do
                xml.send("mf-note") do
                  xml.note note
                end
              end
            end
          end
        end
    end
  end
end
