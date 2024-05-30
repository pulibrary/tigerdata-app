# frozen_string_literal: true
module Mediaflux
  module Http
    class QuotaCreateCollectionRequest < Request
      attr_reader :name, :collection, :allocation

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param collection [String] Id of the collection
      # @param allocation [String] Quota allocation to be set for the collection, e.g. "1 MB" or "1 GB"
      def initialize(session_token:, collection:, allocation:)
        super(session_token: session_token)
        @collection = collection
        @allocation = allocation
        @name = "#{@allocation} quota for #{@collection}"
      end

      # Specifies the Mediaflux service to use when creating assets
      # @return [String]
      def self.service
        "asset.collection.quota.set"
      end

      private

        # The generated XML mimics what we get when we issue an Aterm command as follows:
        # > asset.collection.quota.set :id 1282 :quota
        #     < :allocation 1 MB :on-overflow fail :description "1 MB quota for 1282" >
        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.id @collection
              xml.quota do
                xml.allocation @allocation
                xml.description @name
              end
            end
          end
        end
    end
  end
end
