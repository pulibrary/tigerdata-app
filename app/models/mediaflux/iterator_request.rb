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
    # @return [Hash] with the list of files, the count of files and whether the result is complete or not
    def result
      response_xml if @response_xml.blank?

      result_files = parse_files(@response_xml)
      result_complete_xpath = "/response/reply/result/iterated/@complete"
      result_complete_element = @response_xml.xpath(result_complete_xpath)
      result_complete_element_text = result_complete_element.text
      result_complete = result_complete_element_text == "true"

      result_count_xpath = "/response/reply/result/iterated/@count"
      result_count_element = @response_xml.xpath(result_count_xpath)
      result_count_element_text = result_count_element.text
      result_count = result_count_element_text.to_i

      {
        files: result_files,
        complete: result_complete,
        count: result_count
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

      # @return [Array<Mediaflux::Asset>] the list of files extracted from the XML response
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
      # @return [Array<Mediaflux::Asset>] the list of files extracted from the XML response
      def parse_get_name(xml)
        files = []
        xml.xpath("/response/reply/result/name").each do |node|
          file = Mediaflux::Asset.new(
            id: node.xpath("./@id").text,
            name: node.text,
            type: node.xpath("./type").text,
            collection: node.xpath("./@collection").text == "true"
          )
          files << file
        end
        files
      end

      # @param node [Nokogiri::XML::Node] the XML node containing the file information
      # @return [Mediaflux::Asset] the file information extracted from the XML node
      def build_from_xml_asset(node:)
        Mediaflux::Asset.new(
          id: node.xpath("./@id").text,
          name: node.xpath("./name").text,
          type: node.xpath("./type").text,
          path: node.xpath("./path").text,
          collection: node.xpath("./@collection").text == "true",
          size: node.xpath("./content/@total-size").text.to_i,
          last_modified_mf: node.xpath("mtime").text,
          created_at_mf: node.xpath("ctime").text
        )
      end

      # @param node [Nokogiri::XML::Node] the XML node containing the file information
      # @return [Array<Mediaflux::Asset>] the list of files extracted from the XML node
      def build_from_xml_assets(node:)
        asset_nodes_xpath = "/response/reply/result/asset"
        asset_nodes = node.xpath(asset_nodes_xpath)
        asset_nodes.map do |element|
          build_from_xml_asset(node: element)
        end
      end

      # Extracts file information when the request was made with the "action: get-meta" parameter
      # @return [Array<Mediaflux::Asset>] the list of files extracted from the XML response
      def parse_get_meta(xml)
        build_from_xml_assets(node: xml)
      end

      # Extracts file information when the request was made with the "action: get-values" parameter
      # Notice that this code is coupled with the fields defined in QueryRequest.
      # @return [Array<Mediaflux::Asset>] the list of files extracted from the XML response
      def parse_get_values(xml)
        files = []
        xml.xpath("/response/reply/result/asset").each do |node|
          file = Mediaflux::Asset.new(**parse_asset_attribute(node))
          files << file
        end
        files
        build_from_xml_assets(node: xml)
      end

      def parse_asset_attribute(node)
        {
          id: node.xpath("./@id").text,
          name: node.xpath("./name").text,
          path: node.xpath("./path").text,
          collection: node.xpath("./collection").text == "true",
          size: node.xpath("./total-size").text.to_i,
          last_modified_mf: node.xpath("mtime").text,
          collection_count: node.xpath("./collection-count").text.to_i,
          file_count: node.xpath("./file-count").text.to_i,
          folder_size: node.xpath("./folder-size").text.to_i
        }
      end
  end
end
