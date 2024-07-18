# frozen_string_literal: true
module Mediaflux
  class RangeQueryRequest < Request
    attr_reader :aql_query, :idx, :size, :collection, :namespace, :action

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param collection [Integer] collection id
    # @param xpath [String]  xpath expression for item to calculate the range against
    def initialize(session_token:, collection: nil, xpath: nil)
      super(session_token: session_token)
      @collection = collection
      @xpath = xpath
    end

    # Specifies the Mediaflux service to use when running a query
    # @return [String]
    def self.service
      "asset.query"
    end

    # minimum value for xpath
    def minimum
      min_str = response_xml.xpath("/response/reply/result/value/min").text
      min_str.to_i
    end

    # maximum value for xpath
    def maximum
      max_str = response_xml.xpath("/response/reply/result/value/max").text
      max_str.to_i
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.collection @collection
            xml.action "range"
            xml.xpath @xpath
          end
        end
      end
  end
end
