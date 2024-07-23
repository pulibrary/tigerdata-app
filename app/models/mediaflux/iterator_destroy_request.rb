# frozen_string_literal: true
module Mediaflux
  class IteratorDestroyRequest < Request
    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @iterator [Int] The iterator to destroy (This is the value returned by QueryRequest)
    def initialize(session_token:, iterator:)
      super(session_token: session_token)
      @iterator = iterator
    end

    # Specifies the Mediaflux service to use when running a query
    # @return [String]
    def self.service
      "asset.query.iterator.destroy"
    end

    # Returns empty string if iterator was destroyed, error message otherwise.
    # Notice that once have run through an iterator Mediaflux destroys it automatically
    # so it is possible to get an error indicating that an iterator does not exist if
    # Mediaflux deleted it on its own.
    def result
      xml = response_xml
      xml.xpath("/response/reply['error']").text
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.id @iterator
          end
        end
      end
  end
end
