# frozen_string_literal: true
module Mediaflux
  class Session
    attr_reader :token

    # Constructor
    # @param use_ssl [Boolean] determines whether or not connections to the Mediaflux server API are over the TLS/SSL
    def initialize(use_ssl: false, http_client: nil)
      @http_client = http_client || Mediaflux::Http::Request.build_http_client
      @http_client.use_ssl = use_ssl
    end

    def logon
      logon_request = Mediaflux::Http::LogonRequest.new(http_client: @http_client)
      logon_request.resolve
      @token = logon_request.session_token
    end

    def authenticated?
      @token.present?
    end

    def collections
      logon unless authenticated?

      collection_list_request = Mediaflux::Http::CollectionListRequest.new(http_client: @http_client, session_token: @token)
      response_document = collection_list_request.response_document
      Collection.build_from_response(xml: response_document)
    end
  end
end
