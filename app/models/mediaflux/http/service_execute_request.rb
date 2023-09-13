# frozen_string_literal: true
module Mediaflux
  module Http
    class ServiceExecuteRequest < Request
      attr_reader :token, :service_name, :document

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param service_name  [String] Name of the service to run.
      #                               Can be any command like asset.namespace.list
      # @param token         [String] Optional User token for the person executing the command
      # @param document      [String] Optional xml document to pass on to the service.
      #                               Used to pass parameters to the command
      def initialize(session_token:, service_name:, token: nil, document: nil)
        super(session_token: session_token)
        @service_name = service_name
        @token = token
        @document = document
      end

      # Specifies the Mediaflux service to use when creating assets
      # @return [String]
      def self.service
        "service.execute"
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.token token if token.present?
              xml.service name: service_name do
                xml << document
              end
            end
          end
        end
    end
  end
end
