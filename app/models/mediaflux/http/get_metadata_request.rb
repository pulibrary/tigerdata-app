# frozen_string_literal: true
module Mediaflux
  module Http
    class GetMetadataRequest < Request
      attr_reader :id

      # Constructor
      # @param use_ssl [Boolean] determines whether or not connections to the Mediaflux server API are over the TLS/SSL
      # @param file [File] any upload file required for the POST request
      # @param session_token [String] the API token for the authenticated session
      # @param http_client [Net::HTTP] HTTP client for transmitting requests to the Mediaflux server API
      def initialize(session_token:, id:)
        super(session_token: session_token)
        @id = id
      end

      # Specifies the Mediaflux service to use when listing Collections
      # @return [String]
      def self.service
        "asset.get"
      end

      def metadata
        xml = response_xml
        asset = xml.xpath("/response/reply/result/asset")
        metadata = {
          id: asset.xpath("./@id").text,
          creator: asset.xpath("./creator/user").text,
          description: asset.xpath("./description").text,
          collection: asset.xpath("./@collection")&.text == "true",
          path: asset.xpath("./path").text,
          type: asset.xpath("./type").text,
          size: asset.xpath("./content/size").text,
          size_human: asset.xpath("./content/size/@h").text
        }

        image = asset.xpath("./meta/mf-image")
        if image.count > 0
          metadata[:image_size] = image.xpath("./width").text + " X " + image.xpath("./height").text
        end

        note = asset.xpath("./meta/mf-note")
        if note.count > 0
          metadata[:mf_note] = note.text
        end

        metadata
      end

      private

        def build_http_request_body(name:, request_args: {})
          super do |xml|
            xml.args do
              xml.id id
            end
          end
        end
    end
  end
end
