# frozen_string_literal: true
module Mediaflux
  module Http
    class QueryRequest < Request
      attr_reader :aql_query, :collection, :action, :deep_search

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param aql_query [String] Optional AQL query string
      # @param collection [Integer] Optional collection id
      # @param action [String] Optional, by default it uses get-name but it could also be get-meta to get all
      #                        the fields for the assets or `get-values` to get a limited list of fields.
      # @param deep_search [Bool] Optional, false by default. When true queries the collection and it subcollections.
      def initialize(session_token:, aql_query: nil, collection: nil, action: nil, deep_search: false)
        super(session_token: session_token)
        @aql_query = aql_query
        @collection = collection
        @action = action
        @deep_search = deep_search
      end

      # Specifies the Mediaflux service to use when running a query
      # @return [String]
      def self.service
        "asset.query"
      end

      # Returns the iterator that could be used to fetch the data
      def result
        xml = response_xml
        xml.xpath("/response/reply/result/iterator").text.to_i
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              # TODO: there is a bug in mediaflux that does not allow the comented out line to paginate
              #      For the moment we will utilize the where clasue that does allow pagination
              # xml.collection collection if collection.present?
              if collection.present?
                xml.where mf_where(collection)
              end
              xml.where aql_query if aql_query.present?
              xml.action action if action.present?
              declare_get_values_fields(xml) if action == "get-values"
              xml.as "iterator"
            end
          end
        end

        def mf_where(collection)
          if deep_search
            "asset in static collection or subcollection of #{collection}"
          else
            "asset in collection #{collection}"
          end
        end

        # Adds the declarations to fetch specific fields
        def declare_get_values_fields(xml)
          xml.xpath do
            xml.parent.set_attribute("ename", "name")
            xml.text("name")
          end
          xml.xpath do
            xml.parent.set_attribute("ename", "path")
            xml.text("path")
          end
          xml.xpath do
            xml.parent.set_attribute("ename", "total-size")
            xml.text("content/@total-size")
          end
          xml.xpath do
            xml.parent.set_attribute("ename", "mtime")
            xml.text("mtime")
          end
          xml.xpath do
            xml.parent.set_attribute("ename", "collection")
            xml.text("@collection")
          end
        end
    end
  end
end
