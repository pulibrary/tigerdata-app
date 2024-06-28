# frozen_string_literal: true
module Mediaflux
  module Http
    class CollectionAssetCreateRoot < Request
      attr_reader :namespace, :asset_name, :collection

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param name [String] Name of the root collection asset to create
      def initialize(session_token:, namespace:, name:)
        super(session_token: session_token)
        @namespace = namespace
        @asset_name = name
      end

      # Specifies the Mediaflux service to use when creating the root collection asset
      # @return [String]
      def self.service
        "asset.create"
      end

      def id
        @id ||= response_xml.xpath("/response/reply/result/id").text
        @id
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.namespace namespace
              xml.name asset_name
              collection_xml(xml)
            end
          end
        end

        def collection_xml(xml)
          xml.collection do
            xml.parent.set_attribute("cascade-contained-asset-index", true)
            xml.parent.set_attribute("contained-asset-index", true)
            xml.parent.set_attribute("unique-name-index", true)
            xml.text(true)
          end
          xml.type "application/arc-asset-collection"
        end
    end
  end
end
