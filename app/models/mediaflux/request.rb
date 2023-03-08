# frozen_string_literal: true
module Mediaflux
  class Request
    def self.service
      raise(NotImplementedError, "#{self} is an abstract class, please override #{self}.service")
    end

    def self.service_args
      {}
    end

    def self.request_path
      "__mflux_svc__"
    end

    def self.build_post_request
      Net::HTTP::Post.new(request_path)
    end

    def self.mediaflux
      Rails.configuration.mediaflux
    end

    def self.mediaflux_host
      Rails.configuration.mediaflux["api_host"]
    end

    def self.mediaflux_port
      Rails.configuration.mediaflux["api_port"]
    end

    def self.build_http_client
      Net::HTTP.new(mediaflux_host, mediaflux_port)
    end

    attr_reader :session_token

    # Constructor
    # @param use_ssl [Boolean] determines whether or not connections to the Mediaflux server API are over the TLS/SSL
    # @param session_token [String] the API token for the authenticated session
    def initialize(use_ssl: false, session_token: nil)
      @http_client = self.class.build_http_client
      @http_client.use_ssl = use_ssl
      @session_token = session_token
    end

    def http_request
      @http_request ||= build_http_request(name: self.class.service, request_args: self.class.service_args)
    end

    def resolve
      @http_response = @http_client.request(http_request)
    end

    def http_response
      @http_response ||= resolve
    end

    def resolved?
      @http_response.present?
    end

    def response_document
      resolve unless resolved?

      Rails.logger.debug(http_response.body)
      @response_document ||= Nokogiri::XML.parse(http_response.body)
      Rails.logger.debug(@response_document)

      @response_document
    end

    delegate :to_s, to: :response_document

    private

      def build_http_request_body(name:, request_args: {})
        args = request_args.merge({ name: name })
        args[:session] = session_token unless session_token.nil?

        Nokogiri::XML::Builder.new do |xml|
          xml.request do
            xml.service(**args) do
              yield xml if block_given?
            end
          end
        end
      end

      def build_http_request(name:, form_file: nil, request_args: {})
        request = self.class.build_post_request
        body = build_http_request_body(name: name, request_args: request_args)

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
