# frozen_string_literal: true
module Mediaflux
  module Http
    class StoreListRequest < Request
      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param name [String] Name of the Asset
      # @param collection [Boolean] create a collection asset if true
      # @param namespace [String] Optional Parent namespace for the asset to be created in
      # @param pid [Integer] Optional Parent id for the asset to be created in
      def initialize(session_token:)
        super(session_token: session_token)
      end

      # Specifies the Mediaflux service to use when creating assets
      # @return [String]
      def self.service
        "asset.store.list"
      end

      def stores
        @stores ||= begin
                      xml = response_xml
                      xml.xpath("/response/reply/result/store").map do |node|
                        {
                          id: node.xpath("@id").text,
                          type: node.xpath("./type").text,
                          name: node.xpath("./name").text,
                          tag: node.xpath("./tag").text
                        }
                      end
                    end
      end
    end
  end
end
