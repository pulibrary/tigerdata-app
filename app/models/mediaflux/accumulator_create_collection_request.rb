# frozen_string_literal: true
module Mediaflux
  class AccumulatorCreateCollectionRequest < Request
    attr_reader :namespace, :asset_name, :collection

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param collection [String] Id of the collection
    # @param name [String] Name of the Accumulator
    # @param type [String] type of the Accumulator
    #     	"collection.asset.count"
    #      	"content.all.copy.tag.size"
    #     	"content.all.size"
    #      	"content.all.store.size"
    #      	"content.all.store.size.by.owner"
    #      	"content.all.store.size.by.xpath"
    #      	"content.all.type.size"
    def initialize(session_token:, collection:, name:, type:)
      super(session_token: session_token)
      @name = name
      @collection = collection
      @type = type
    end

    # Specifies the Mediaflux service to use when creating assets
    # @return [String]
    def self.service
      "asset.collection.accumulator.add"
    end

    private

      # The generated XML mimics what we get when we issue an Aterm command as follows:
      # > asset.collection.accumulator.add :id 3218 :cascade true
      #      :accumulator < :name mytest-01509-count :type collection.asset.count >
      #
      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.id @collection
            xml.cascade true
            xml.accumulator do
              xml.name @name
              xml.type @type
            end
          end
        end
      end
  end
end
