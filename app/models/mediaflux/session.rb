# frozen_string_literal: true
module Mediaflux
  class Session
    attr_reader :session_token

    # Constructor
    # @param use_ssl [Boolean] determines whether or not connections to the Mediaflux server API are over the TLS/SSL
    def initialize(use_ssl: false)
      @http_client = self.class.build_http_client
      @http_client.use_ssl = use_ssl
    end

    def logon
      logon_request = LogonRequest.new
      logon_request.resolve
      @session_token = logon_request.session_token
    end

    def authenticated?
      @session_token.present?
    end

    def collections
      collection_list_request = CollectionListRequest.new
      response_document = collection_list_request.response_document
      Collection.build_from_xml(response_document)
    end
  end
end
