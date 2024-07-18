# frozen_string_literal: true
module Mediaflux
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

    private

      def build_http_request_body(name:)
        super(name: name) do |xml|
          xml.args do
            xml.namespace self.class.default_namespace
          end
        end
      end
  end
end
