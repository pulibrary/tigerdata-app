# frozen_string_literal: true
module Mediaflux
  class IteratorRequest < Request
    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @iterator [Int] The iterator returned by Mediaflux (via QueryRequest)
    def initialize(session_token:, iterator:, action: "get-values", size: nil)
      super(session_token: session_token)
      @iterator = iterator
      @size = size
      @action = action
    end

    # Specifies the Mediaflux service to use when running a query
    # @return [String]
    def self.service
      "asset.query.iterate"
    end

    # Returns hash with the files fetched in this iteration as well as a flag on whether we are
    # done iterating (complete=true) or if we need to keep iterating
    def result
      xml = response_xml
      {
        files: parse_files(xml),
        complete: xml.xpath("/response/reply/result/iterated/@complete").text == "true",
        count: xml.xpath("/response/reply/result/iterated").text.to_i
      }
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.id @iterator
            xml.size @size if @size.present?
          end
        end
      end

      def parse_files(xml)
        case @action
        when "get-name"
          parse_get_name(xml)
        when "get-meta"
          parse_get_meta(xml)
        when "get-values"
          parse_get_values(xml)
        else
          raise "Cannot parse result. Unknow action: #{@action}."
        end
      end

      # Extracts file information when the request was made with the "action: get-name" parameter
      def parse_get_name(xml)
        files = []
        xml.xpath("/response/reply/result/asset").each do |node|
          file = Mediaflux::Asset.new(
            id: node.xpath("./@id").text,
            name: node.xpath("./name").text,
            collection: node.xpath("./collection").text == "true"
          )
          files << file
        end
        files
      end

      # Extracts file information when the request was made with the "action: get-meta" parameter
      def parse_get_meta(xml)
        files = []
        xml.xpath("/response/reply/result/asset").each do |node|
          file = Mediaflux::Asset.new(
            id: node.xpath("./@id").text,
            name: node.xpath("./name").text,
            path: node.xpath("./path").text,
            collection: node.xpath("./@collection").text == "true",
            size: node.xpath("./content/@total-size").text.to_i,
            last_modified_mf: node.xpath("mtime").text
          )
          files << file
        end
        files
      end

      # Extracts file information when the request was made with the "action: get-values" parameter
      # Notice that this code is coupled with the fields defined in QueryRequest.
      def parse_get_values(xml)
        files = []
        xml.xpath("/response/reply/result/asset").each do |node|
          file = Mediaflux::Asset.new(**parse_asset_attribute(node))
          files << file
        end
        files
      end

      def parse_asset_attribute(node)
        {
          id: node.xpath("./@id").text,
          name: node.xpath("./name").text,
          path: node.xpath("./path").text,
          collection: node.xpath("./collection").text == "true",
          size: node.xpath("./total-size").text.to_i,
          last_modified_mf: node.xpath("mtime").text,
          created_on_mf: node.xpath("ctime").text,
          creator: { uid: node.xpath("creator_uid").text, name: node.xpath("creator_name").text, domain: node.xpath("creator_domain").text },
          collection_count: node.xpath("./collection-count").text.to_i,
          file_count: node.xpath("./file-count").text.to_i,
          folder_size: node.xpath("./folder-size").text.to_i
        }
      end
  end
end
