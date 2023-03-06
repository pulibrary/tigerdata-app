# frozen_string_literal: true
module Mediaflux
  class CollectionList < Connection
    def initialize
      super
      response = build_request("asset.collection.list")
      @doc = Nokogiri::XML.parse(response.body)
    end

    def to_s
      @doc.to_s
    end
  end
end
