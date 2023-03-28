# frozen_string_literal: true
module Mediaflux
  module Http
    class CollectionListRequest < Request
      # Specifies the default namespace to use when listing Collections
      # @return [String]
      def self.default_namespace
        "tigerdata"
      end

      # Specifies the Mediaflux service to use when listing Collections
      # @return [String]
      def self.service
        "asset.collection.list"
      end

      # Provides the arguments for the Mediaflux service used to list collections
      # @return [Hash]
      def self.service_args
        {
          namespace: default_namespace
        }
      end
    end
  end
end
