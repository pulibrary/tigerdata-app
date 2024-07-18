# frozen_string_literal: true
module Mediaflux
  class AssetExistRequest < Request
    # Constructor
    # @param session_token [String] the API token for the authenticated session
    def initialize(session_token:, path:, session_user: nil)
      super(session_token: session_token, session_user: session_user)
      @path = path
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "asset.exists"
    end

    # Be aware that asset.exists does not return the ID of the asset validated
    # so we cannot return it back to the user (Mediaflux returns the path that
    # we validated but not the actual asset ID. Hence we return true/false for
    # this kind of request.
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
