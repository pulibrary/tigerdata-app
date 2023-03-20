# frozen_string_literal: true
module Mediaflux
  class CollectionList < Connection
    attr_reader :collections
    def initialize
      super
      response = build_request("asset.collection.list")
      @doc = Nokogiri::XML.parse(response.body)
      @collections = @doc.xpath("response/reply/result/collection")
    end

    def to_s
      collections.to_s
    end
  end
end
