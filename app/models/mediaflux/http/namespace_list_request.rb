# frozen_string_literal: true
module Mediaflux
  module Http
    class NamespaceListRequest < Request
      attr_reader :parent_namespace

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param name [String] Name of the Asset
      # @param collection [Boolean] create a collection asset if true
      # @param namespace [String] Optional Parent namespace for the asset to be created in
      # @param pid [Integer] Optional Parent id for the asset to be created in
      def initialize(session_token:, parent_namespace:)
        super(session_token: session_token)
        @parent_namespace = parent_namespace
      end

      # Specifies the Mediaflux service to use when creating assets
      # @return [String]
      def self.service
        "asset.namespace.list"
      end

      def namespaces
        @namespaces ||= begin
                          xml = response_xml
                          namespaces = []
                          xml.xpath("/response/reply/result/namespace/namespace").each.each do |ns|
                            id = ns.xpath("@id").text
                            namespaces << { id: id, name: ns.text }
                          end
                          namespaces
                        end
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.namespace parent_namespace
            end
          end
        end
    end
  end
end
