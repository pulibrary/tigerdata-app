# frozen_string_literal: true
module Mediaflux
  module Http
    class NamespaceDescribeRequest < Request
      attr_reader :path, :id

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param name [String] Name of the Asset
      # @param collection [Boolean] create a collection asset if true
      # @param namespace [String] Optional Parent namespace for the asset to be created in
      # @param pid [Integer] Optional Parent id for the asset to be created in
      def initialize(session_token:, path: nil, id: nil)
        super(session_token: session_token)
        @path = path
        @id = id
      end

      # Specifies the Mediaflux service to use when creating assets
      # @return [String]
      def self.service
        "asset.namespace.describe"
      end

      def metadata
        @metadata ||= begin
                        xml = response_xml
                        node = xml.xpath("/response/reply/result/namespace")
                        {
                          id: node.xpath("@id").text,
                          path: node.xpath("./path").text,
                          name: node.xpath("./name").text,
                          description: node.xpath("./description").text,
                          store: node.xpath("./store").text
                        }
                      end
      end

      def exists?
        metadata[:id].present?
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.id id if id.present?
              xml.namespace path if path.present?
            end
          end
        end
    end
  end
end
