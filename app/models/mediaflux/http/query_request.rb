# frozen_string_literal: true
module Mediaflux
  module Http
    class QueryRequest < Request
      attr_reader :aql_query, :idx, :size, :collection, :namespace, :action

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param http_client [String] Optional AQL query string
      # @param collection [Integer] Optional collection id
      # @param idx [Integer] Optional starting index or return set.  Defaults to 1
      # @param size [Integer] Optional page size.  Defaults to 100
      def initialize(session_token:, aql_query: nil, collection: nil, idx: 1, size: 100, namespace: nil, action: nil)
        super(session_token: session_token)
        @aql_query = aql_query
        @collection = collection
        @namespace = namespace
        @action = action
        @idx = idx
        @size = size
      end

      # Specifies the Mediaflux service to use when running a query
      # @return [String]
      def self.service
        "asset.query"
      end

      # Parse the result of the query into a hash with a list of ids and a cursor to show
      #  you where you are in the paginated results
      def result
        xml = response_xml
        ids = xml.xpath("/response/reply/result/id").children.map(&:text)

        # total is only the actual total when the "complete" attribute is true,
        # otherwise it reflects the total fetched so far
        {
          ids: ids,
          size: xml.xpath("/response/reply/result/size").text.to_i,
          cursor: parse_cursor(xml.xpath("/response/reply/result/cursor")),
          files: parse_files(xml)
        }
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.where "namespace=#{namespace}" if namespace.present?
              # TODO: there is a bug in mediaflux that does not allow the comented out line to paginate
              #      For the moment we will utilize the where clasue that does allow pagination
              # xml.collection collection if collection.present?
              xml.where "asset in static collection or subcollection of #{collection}" if collection.present?
              xml.where aql_query if aql_query.present?
              xml.action action if action.present?
              xml.idx idx
              xml.size size
            end
          end
        end

        def parse_cursor(cursor)
          {
            count: cursor.xpath("./count").text.to_i,
            from: cursor.xpath("./from").text.to_i,
            to: cursor.xpath("./to").text.to_i,
            prev: cursor.xpath("./prev").text.to_i,
            next: cursor.xpath("./next").text.to_i,
            total: cursor.xpath("./total").text.to_i,
            remaining: cursor.xpath("./remaining").text.to_i
          }
        end

        def parse_files(xml)
          if action == "get-name"
            parse_get_name(xml)
          else
            parse_get_meta(xml)
          end
        end

        # Extracts file information when the request was made with the "action: get-name" parameter
        def parse_get_name(xml)
          files = []
          xml.xpath("/response/reply/result").children.each do |node|
            if node.name == "name"
              file = Mediaflux::Asset.new(
                id: node.xpath("./@id").text,
                name: node.text,
                collection: node.xpath("./@collection").text == "true",
              )
              files << file
            else
              # it's the cursor node, ignore it
              next
            end
          end
          files
        end

        # Extracts file information when the request was made with the "action: get-meta" parameter
        def parse_get_meta(xml)
          files = []
          xml.xpath("/response/reply/result").children.each do |node|
            if node.name == "asset"
              file = Mediaflux::Asset.new(
                id: node.xpath("./@id").text,
                name: node.xpath("./name").text,
                path: node.xpath("./path").text,
                collection: node.xpath("./@collection").text == "true",
                size: node.xpath("./content/@total-size").text.to_i,
                last_modified_mf: node.xpath("mtime").text,
                tz: node.xpath("mtime/@tz").text
              )
              files << file
            else
              # it's the cursor node, ignore it
              next
            end
          end
          files
        end
    end
  end
end
