# frozen_string_literal: true
module Mediaflux
  class CollectionQueryRequest < QueryRequest
    def initialize(session_token:, namespace: nil, action: "get-meta")
      super(session_token: session_token, namespace: namespace, aql_query: "asset is collection", action: action)
    end

    def collections
      xml = response_xml
      collection_assets = []
      xml.xpath("/response/reply/result/asset").each do |node|
        collection_asset = {
          id: node.xpath("./@id").text,
          path: node.xpath("./path").text,
          name: node.xpath("./name").text,
          description: node.xpath("./description").text
        }
        collection_assets << collection_asset
      end
      collection_assets
    end
  end
end
