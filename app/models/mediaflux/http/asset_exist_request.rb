# frozen_string_literal: true
module Mediaflux
  module Http
    class AssetExistRequest < Request

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      def initialize(session_token:, path:)
        super(session_token: session_token)
        @path = path
      end

      # Specifies the Mediaflux service to use
      # @return [String]
      def self.service
        "asset.exists"
      end

      def exist?
        response_xml.xpath("/response/reply/result/exists").text == "true"
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.id "path=#{@path}"
            end
          end
        end
    end
  end
end
