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
      def initialize(session_token:, namespace: nil, name:, collection: true, parent_id: nil, tigerdata_values: nil)
        super(session_token: session_token)
        @namespace = namespace
        @asset_name = name
        @collection = collection
        @parent_id = parent_id
        @tigerdata_values = tigerdata_values
      end

      # Specifies the Mediaflux service to use when creating assets
      # @return [String]
      def self.service
        "asset.create"
      end

      def id
        @id ||= response_xml.xpath("/response/reply/result/id").text
        @id
      end

      private

        # asset.set :id path=/sandbox_ns/rdss_collection
        #       :meta <
        #           :sandbox_meta:project <
        #             :name "RDSS test project"
        #             :sponsor "Library"
        #             :max_gb 100
        #             :created_on "31-AUG-2023"
        #           >
        #         >
        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.name asset_name
              xml.namespace namespace if namespace.present?
              xml.pid parent_id if parent_id.present?
              if @tigerdata_values
                xml.meta do
                  xml.send("tigerdata:simple", "xmlns:tigerdata" => "tigerdata") do
                    xml.data_sponsor "hc8719"
                  end
                end
              end
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
