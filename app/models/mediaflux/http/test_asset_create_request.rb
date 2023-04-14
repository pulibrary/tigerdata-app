# frozen_string_literal: true
module Mediaflux
  module Http
    class TestAssetCreateRequest < Request
      attr_reader :parent_id, :count, :pattern

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param parent_id [Integer] nid of namespace or collection to create the test assets in
      # @param count [Integer] Number of assets to create (default 1)
      # @param pattern [String] Optional base name of the assets to create
      def initialize(session_token:, parent_id:, count: 1, pattern: nil)
        super(session_token: session_token)
        @parent_id = parent_id
        @count = count
        @pattern = pattern
      end

      # Specifies the Mediaflux service to use when creating assets
      # @return [String]
      def self.service
        "asset.test.create"
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.pid parent_id
              xml.nb count
              xml.send("base-name", pattern) if pattern.present?
            end
          end
        end
    end
  end
end
