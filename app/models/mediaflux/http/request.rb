# frozen_string_literal: true
module Mediaflux
  module Http
    class Request
      # As this is an abstract class, this should be overridden to specify the Mediaflux API service
      def self.service
        raise(NotImplementedError, "#{self} is an abstract class, please override #{self}.service")
      end

      # The default request URL path for the Mediaflux API
      # @return [String]
      def self.request_path
        "/__mflux_svc__"
      end

      # Constructs a new HTTP POST request for usage with the Mediaflux API
      # @return [Net::HTTP::Post]
      def self.build_post_request
        Net::HTTP::Post.new(request_path)
      end

      # The Rails configuration options specifying the Mediaflux server
      # @return [Hash]
      def self.mediaflux
        Rails.configuration.mediaflux
      end

      # The host URL for the Mediaflux server
      # @return [String]
      def self.mediaflux_host
        Rails.configuration.mediaflux["api_host"]
      end

      # The host port for the Mediaflux server
      # @return [String]
      def self.mediaflux_port
        Rails.configuration.mediaflux["api_port"]
      end

      # Constructs a new HTTP client for usage with the Mediaflux API
      # @return [Net::HTTP]
      def self.build_http_client
        Net::HTTP.new(mediaflux_host, mediaflux_port)
      end

      attr_reader :session_token

      # Constructor
      # @param use_ssl [Boolean] determines whether or not connections to the Mediaflux server API are over the TLS/SSL
      # @param file [File] any upload file required for the POST request
      # @param session_token [String] the API token for the authenticated session
      # @param http_client [Net::HTTP] HTTP client for transmitting requests to the Mediaflux server API
      def initialize(use_ssl: false, file: nil, session_token: nil, http_client: nil)
        @http_client = http_client || self.class.build_http_client
        @http_client.use_ssl = use_ssl

        @file = file
        @session_token = session_token
      end

      # Resolves the HTTP request against the Mediaflux API
      # @return [Net::HTTP]
      def resolve
        @http_response = @http_client.request(http_request)
      end

      # Determines whether or not the request has been resolved
      # @return [Boolean]
      def resolved?
        @http_response.present?
      end

      # Resolves the HTTP request, and returns the XML Document parsed from the response body
      # @return [Nokogiri::XML::Document]
      def response_xml
        resolve unless resolved?

        Rails.logger.debug(response_body)
        @response_xml ||= Nokogiri::XML.parse(response_body)
        Rails.logger.debug(@response_xml)
        if @response_xml.xpath("//message").text == "session is not valid"
          raise Mediaflux::Http::SessionExpired, session_token
        end

        @response_xml
      end

      # The response body of the mediaflux call
      def response_body
        @response_body ||= http_response.body
      end

      delegate :to_s, to: :response_xml

      private

        def http_request
          @http_request ||= build_http_request(name: self.class.service, form_file: @file)
        end

        def http_response
          @http_response ||= resolve
        end

        def build_http_request_body(name:)
          args = { name: name }
          args[:session] = session_token unless session_token.nil?

          Nokogiri::XML::Builder.new do |xml|
            xml.request do
              xml.service(**args) do
                yield xml if block_given?
              end
            end
          end
        end

        def build_http_request(name:, form_file: nil)
          request = self.class.build_post_request
          body = build_http_request_body(name: name)
          Rails.logger.debug(body.to_xml)
          if form_file.nil?
            request["Content-Type"] = "text/xml; charset=utf-8"
            request.body = body.to_xml
          else
            request["Content-Type"] = "multipart/form-data"
            request.set_form({ "request" => body.to_xml,
                               "nb-data-attachments" => "1",
                               "file_0" => form_file },
                          "multipart/form-data",
                          "charset" => "UTF-8")
          end

          request
        end
    end
  end
end
