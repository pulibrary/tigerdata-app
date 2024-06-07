# frozen_string_literal: true
module Mediaflux
  module Http
    class AssetCreateRequest < Request
      attr_reader :namespace, :asset_name, :collection

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param name [String] Name of the Asset
      # @param namespace [String] Optional Parent namespace for the asset to be created in
      # @param pid [String] Optional Parent collection id (use this or a namespace not both)
      # @param xml_namespace [String]
      def initialize(session_token:, namespace: nil, name:, xml_namespace: nil, xml_namespace_uri: nil, pid: nil)
        super(session_token: session_token)
        @namespace = namespace
        @asset_name = name
        @xml_namespace = xml_namespace || self.class.default_xml_namespace
        @xml_namespace_uri = xml_namespace_uri || self.class.default_xml_namespace_uri
        @pid = pid
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

        # The generated XML mimics what we get when we issue an Aterm command as follows:
        # > asset.set :id path=/sandbox_ns/rdss_collection
        #     :meta <
        #       :tigerdata:project <
        #         :title "RDSS test project"
        #         :description "The description of the project"
        #         ...the rest of the fields go here..
        #       >
        #     >
        #
        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.name asset_name
              xml.namespace namespace if namespace.present?
              yield xml if block_given?
              collection_xml(xml)
              if @pid.present?
                xml.pid @pid
              end
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
