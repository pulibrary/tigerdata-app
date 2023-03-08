# frozen_string_literal: true
module Mediaflux
  class CollectionListRequest < Request

    def self.default_namespace
      "tigerdata"
    end

    def self.service
      "asset.collection.list"
    end

    def self.service_args
      {
        namespace: default_namespace
      }
    end
  end
end
