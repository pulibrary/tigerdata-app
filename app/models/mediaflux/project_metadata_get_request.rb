# frozen_string_literal: true
module Mediaflux
  class ProjectMetadataGetRequest < Request
    # Constructor
    # @param id [Integer] The Mediaflux id of the asset to fetch
    def initialize(session_token:, id:, session_user: nil)
      super(session_token: session_token, session_user: session_user)
      @id = id
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "asset.get"
    end

    def title
      response_xml.xpath("response/reply/result/asset/meta//Title").text
    end

    def id
      response_xml.xpath("response/reply/result/asset/@id").text.to_i
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.id @id
          end
        end
      end
  end
end
