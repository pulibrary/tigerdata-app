# frozen_string_literal: true
module Mediaflux
  module Http
    class CreateAssetRequest < Request
      attr_reader :namespace, :asset_name, :collection, :parent_id

      # Constructor
      # @param use_ssl [Boolean] determines whether or not connections to the Mediaflux server API are over the TLS/SSL
      # @param file [File] any upload file required for the POST request
      # @param session_token [String] the API token for the authenticated session
      # @param http_client [Net::HTTP] HTTP client for transmitting requests to the Mediaflux server API
      def initialize(session_token:, namespace: nil, name:, collection: true, parent_id: nil)
        super(session_token: session_token)
        @namespace = namespace
        @asset_name = name
        @collection = collection
        @parent_id = parent_id
      end

      # Specifies the Mediaflux service to use when listing Collections
      # @return [String]
      def self.service
        "asset.create"
      end

      def response_body
        http_response.body
      end

      private

        def build_http_request_body(name:, request_args: {})
          super do |xml|
            xml.args do
              xml.name asset_name
              xml.namespace namespace if namespace.present?
              xml.pid parent_id if parent_id.present?
              if collection
                xml.collection do
                  xml.parent.set_attribute("contained-asset-index", true)
                  xml.parent.set_attribute("unique-name-index", true)
                  xml.text(collection)
                end
                xml.type "application/arc-asset-collection"
              end
            end
          end
        end
    end
  end
end
