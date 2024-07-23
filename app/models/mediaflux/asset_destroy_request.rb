# frozen_string_literal: true
module Mediaflux
  class AssetDestroyRequest < Request
    attr_reader :collection, :members

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param collection [Int] the identifier of the collection to be destroyed
    # @param members [Boolean] A true/false flag the can destroy all members of a collection

    def initialize(session_token:, collection:, members:)
      super(session_token: session_token)
      @collection = collection
      @members = members
    end

    # Specifies the Mediaflux service to use when destroying assets
    # @return [String]
    def self.service
      "asset.destroy"
    end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.id collection
              xml.members members
            end
          end
        end
  end
end
