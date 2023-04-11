# frozen_string_literal: true
module Mediaflux
  module Http
    class CreateAssetRequest < Request
      attr_reader :namespace, :asset_name, :collection, :parent_id

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param name [String] Name of the Asset
      # @param collection [Boolean] create a collection asset if true
      # @param namespace [String] Optional Parent namespace for the asset to be created in
      # @param pid [Integer] Optional Parent id for the asset to be created in
      def initialize(session_token:, namespace: nil, name:, collection: true, parent_id: nil)
        super(session_token: session_token)
        @namespace = namespace
        @asset_name = name
        @collection = collection
        @parent_id = parent_id
      end

      # Specifies the Mediaflux service to use when creating assets
      # @return [String]
      def self.service
        "asset.create"
      end

      private

        def build_http_request_body(name:)
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
