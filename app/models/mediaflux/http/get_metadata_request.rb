# frozen_string_literal: true
module Mediaflux
  module Http
    class GetMetadataRequest < Request
      attr_reader :id

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param id [Integer] Id of the Asset to return the metadata for
      def initialize(session_token:, id:)
        super(session_token: session_token)
        @id = id
      end

      # Specifies the Mediaflux service to use when getting asset metadata
      # @return [String]
      def self.service
        "asset.get"
      end

      # parse the returned XML into a hash about the asset that can be utilized
      def metadata
        xml = response_xml
        asset = xml.xpath("/response/reply/result/asset")
        metadata = parse(asset)

        if metadata[:collection]
          metadata[:total_file_count] = asset.xpath("./collection/accumulator/value/non-collections").text
        end

        parse_image(asset.xpath("./meta/mf-image"), metadata) # this does not do anything because mf-image is not a part of the meta xpath

        parse_note(asset.xpath("./meta/mf-note"), metadata) # this does not do anything because mf-note is not a part of the meta xpath

        metadata
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.id id
            end
          end
        end

        def parse_note(note, metadata)
          if note.count > 0
            metadata[:mf_note] = note.text
          end
        end

        def parse_image(image, metadata)
          if image.count > 0
            metadata[:image_size] = image.xpath("./width").text + " X " + image.xpath("./height").text
          end
        end

        def parse(asset)
          {
            id: asset.xpath("./@id").text,
            creator: asset.xpath("./creator/user").text,
            description: asset.xpath("./description").text,
            collection: asset.xpath("./@collection")&.text == "true",
            path: asset.xpath("./path").text,
            type: asset.xpath("./type").text,
            size: asset.xpath("./content/size").text,
            size_human: asset.xpath("./content/size/@h").text,
            namespace: asset.xpath("./namespace").text,
            accumulators: asset.xpath("./collection/accumulator/value") # list of accumulator values in xml format. Can parse further through xpath
          }
        end
    end
  end
end
