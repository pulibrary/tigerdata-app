# frozen_string_literal: true
module Mediaflux
  module Http
    class QueryRequest < Request
      attr_reader :aql_query, :idx, :size, :collection

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param http_client [String] Optional AQL query string
      # @param collection [Integer] Optional collection id
      # @param idx [Integer] Optional starting index or return set.  Defaults to 1
      # @param size [Integer] Optional page size.  Defaults to 10
      def initialize(session_token:, aql_query: nil, collection: nil, idx: 1, size: 10)
        super(session_token: session_token)
        @aql_query = aql_query
        @collection = collection
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
          cursor: parse_cursor(xml.xpath("/response/reply/result/cursor"))
        }
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.where aql_query if aql_query.present?
              xml.collection collection if collection.present?
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
    end
  end
end
