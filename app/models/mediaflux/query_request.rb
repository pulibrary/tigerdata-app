# frozen_string_literal: true
module Mediaflux
  class QueryRequest < Request
    attr_reader :aql_query, :collection, :action, :deep_search, :iterator

    # Default action for query requests
    # @return [String] default action name
    def self.default_action
      "get-values"
    end

    # Fields to retrieve when using get-values action
    # @return [Hash] mapping of XPath expressions to field names
    def self.query_fields
      {
        "name" => "name",
        "path" => "path",
        "content/@total-size" => "total-size",
        "mtime" => "mtime",
        "@collection" => "collection"
      }
    end

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param aql_query [String] Optional AQL query string
    # @param collection [Integer] Optional collection id
    # @param action [String] Optional, by default it uses get-values but it could also be get-meta to get all
    #                        the fields for the assets or `get-name` to get a limited list of fields.
    # @param deep_search [Bool] Optional, false by default. When true queries the collection and it subcollections.
    # @param iterator [Bool] Optional, true by default. When true returns an iterator.  When false returns a list of results
    def initialize(session_token:, aql_query: nil, collection: nil, action: nil, deep_search: false, iterator: true)
      super(session_token: session_token)
      @aql_query = aql_query
      @collection = collection
      @action = action || self.class.default_action
      @deep_search = deep_search
      @iterator = iterator
    end

    # Specifies the Mediaflux service to use when running a query
    # @return [String]
    def self.service
      "asset.query"
    end

    # Returns the iterator ID that could be used to fetch the data in batches
    # @return [Integer] iterator identifier
    def result
      xml = response_xml
      xml.xpath("/response/reply/result/iterator").text.to_i
    end

    # Returns a list of asset items when iterator is false
    # Each item contains id, name, and path
    # @return [Array<Hash>] array of asset hashes with :id, :name, :path keys
    # @raise [RuntimeError] if iterator mode is enabled
    def result_items
      raise "Cannot get result items when using iterator mode" if iterator

      xml = response_xml
      xml.xpath("/response/reply/result").children.map do |node|
        {
          id: node.xpath("./@id").text,
          name: node.xpath("./name").text,
          path: node.xpath("./path").text
        }
      end
    end

    private

      # Builds the HTTP request body with query parameters
      # @param name [String] service name (unused in this implementation)
      # @return [Nokogiri::XML::Builder]
      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            # NOTE: Due to a MediaFlux bug, using xml.collection with pagination (iterator mode)
            # causes issues. As a workaround, we use the 'where' clause instead which supports pagination.
            # This allows us to query collections while maintaining iterator functionality.
            add_collection_filter(xml) if collection.present?
            xml.where aql_query if aql_query.present?
            xml.action action if action.present?
            declare_get_values_fields(xml) if action == self.class.default_action
            xml.as "iterator" if iterator
          end
        end
      end

      # Adds collection filtering using the where clause
      # @param xml [Nokogiri::XML::Builder] XML builder instance
      def add_collection_filter(xml)
        xml.where mf_where(collection)
      end

      # Builds the where clause for collection filtering
      # @param collection [Integer] collection ID
      # @return [String] where clause string
      def mf_where(collection)
        if deep_search
          "asset in static collection or subcollection of #{collection}"
        else
          "asset in collection #{collection}"
        end
      end

      # Adds field declarations for get-values action
      # @param xml [Nokogiri::XML::Builder] XML builder instance
      def declare_get_values_fields(xml)
        self.class.query_fields.each do |xpath, name|
          declare_get_value_field(xml, xpath, name)
        end
      end

      # Adds a single field declaration for xpath query
      # @param xml [Nokogiri::XML::Builder] XML builder instance
      # @param field_xpath [String] XPath expression for the field
      # @param field_name [String] name attribute for the field
      def declare_get_value_field(xml, field_xpath, field_name)
        xml.xpath(ename: field_name) do
          xml.text(field_xpath)
        end
      end
  end
end
