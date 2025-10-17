# frozen_string_literal: true
module Mediaflux
  class HttpConnection
    include Singleton

    attr_reader :http_client

    # This ensures that, once the Class is out of scope, the Net::HTTP::Persistent connection is closed
    class << self
      def finalizer(http_client)
        proc {
          Rails.logger.debug "finalized http"
          http_client&.shutdown
        }
      end
    end

    def initialize
      @http_client = Net::HTTP::Persistent.new
      @http_client.read_timeout = 240 # seconds
      Rails.logger.debug "created http with 240 seconds timeout"
      # https is not working correctly on td-meta1 we should not need this, but we do...
      @http_client.verify_mode = OpenSSL::SSL::VERIFY_NONE

      ObjectSpace.define_finalizer(self, self.class.finalizer(@http_client))
    end
  end
end
