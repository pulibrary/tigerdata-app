# frozen_string_literal: true
module Mediaflux
  module Http
    class CollectionCountRequest < Request

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param namespace [String] Namespace to limit the search
      # @param data_sponsor [String] Datasponsor for the collection
      # @param data_sponsor [String] Department assigned to the collection
      def initialize(session_token:, namespace:, data_sponsor: nil, department: nil)
        super(session_token: session_token)
        @namespace = namespace
        @data_sponsor = data_sponsor
        @department = department
      end

      # Specifies the Mediaflux service to use
      # @return [String]
      def self.service
        "asset.count"
      end

      def count
        @count ||= response_xml.xpath("/response/reply/result/total").text
        @count
      end

      private

        def build_http_request_body(name:)
          super(name: name) do |xml|
            xml.args do
              xml.namespace @namespace
              xml.where build_where_clause
            end
          end
        end

        def build_where_clause
          where_clause = "asset is collection"
          if @data_sponsor
            where_clause += " AND tigerdata:project/data_sponsor='#{@data_sponsor}'"
          end
          if @department
            where_clause += " AND tigerdata:project/departments='#{@department}'"
          end
          where_clause
        end
    end
  end
end
