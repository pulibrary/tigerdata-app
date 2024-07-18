# frozen_string_literal: true
module Mediaflux
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

      def self.uri
        URI("#{Connection.transport}://#{Connection.host}:#{Connection.port}/#{request_path}")
      end

      # Constructs a new HTTP POST request for usage with the Mediaflux API
      # @return [Net::HTTP::Post]
      def self.build_post_request
        Net::HTTP::Post.new(request_path)
      end

      # The default XML namespace which should be used for building the XML
      #   Document transmitted in the body of the HTTP request
      # @return [String]
      def self.default_xml_namespace
        "tigerdata"
      end

      def self.default_xml_namespace_uri
        "http://tigerdata.princeton.edu"
      end

      # Constructs and memoizes a new instance of the Net::HTTP::Persistent object at the level of the Class
      # @returns http_client [Net::HTTP::Persistent] HTTP client for transmitting requests to the Mediaflux server API
      def self.find_or_create_http_client
        HttpConnection.instance.http_client
      end

      attr_reader :session_token

      # Constructor
      # @param file [File] any upload file required for the POST request
      # @param session_token [String] the API token for the authenticated session
      # @param http_client [Net::HTTP::Persistent] HTTP client for transmitting requests to the Mediaflux server API
      def initialize(file: nil, session_token: nil, http_client: nil)
        @http_client = http_client || self.class.find_or_create_http_client
        @file = file
        @session_token = session_token
      end

      # Resolves the HTTP request against the Mediaflux API
      # @return [Net::HTTP]
      def resolve
        @http_response = @http_client.request self.class.uri, http_request
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
          raise Mediaflux::SessionExpired, session_token
        end

        @response_xml
      end

      # The response body of the mediaflux call
      def response_body
        @response_body ||= http_response.body
      end

      def error?
        response_error.present?
      end

      def response_error
        xml = response_xml
        return nil if xml.xpath("/response/reply/error").count == 0
        error = {
          title: xml.xpath("/response/reply/error").text,
          message: xml.xpath("/response/reply/message").text
        }
        Rails.logger.error "MediaFlux error: #{error[:title]}, #{error[:message]}"
        error
      end

      delegate :to_s, to: :response_xml

      def xml_payload( name: self.class.service)
        body = build_http_request_body(name: )
        xml_payload = body.to_xml
      end

      # The output of this routine can be passed to xtoshell in aterm.  The output of which can be sent to service.execute
      # @param [String] name name of the service this request will send
      # @return [String] xml that can be passed to xtoshell without manipulation
      def xtoshell_xml( name: self.class.service)
        xml_builder = build_http_request_body(name: )
        xml_builder.doc.xpath("//request/service/@session").remove
        xml = xml_builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
        xml.strip.gsub("\"","'").gsub("<args>","").gsub("</args>","")
      end

      # This method is used for transforming iso8601 dates to dates that MediaFlux likes
      # Take a string like "2024-02-26T10:33:11-05:00" and convert this string to "22-FEB-2024 13:57:19"
      def self.format_date_for_mediaflux(iso8601_date)
        return if iso8601_date.nil?
        Time.format_date_for_mediaflux(iso8601_date)
      end

      private

        def http_request
          @http_request ||= build_http_request(name: self.class.service, form_file: @file)
        end

        def http_response
          @http_response ||= resolve
        end

        def build_http_request_body(name:)
          args = { name: name }
                                                # must use @session_token here instead of session_token 
                                                #  for login to not go into an infinaite loop
          args[:session] = session_token unless @session_token.nil?

          Nokogiri::XML::Builder.new(namespace_inheritance: false) do |xml|
            xml.request do
              xml.service(**args) do
                yield xml if block_given?
              end
            end
          end
        end

        # rubocop:disable Metrics/MethodLength
        def build_http_request(name:, form_file: nil)
          request = self.class.build_post_request

          Rails.logger.debug(xml_payload)
          if form_file.nil?
            request["Content-Type"] = "text/xml; charset=utf-8"
            request.body = xml_payload(name:)
          else
            request["Content-Type"] = "multipart/form-data"
            request.set_form({ "request" => xml_payload,
                               "nb-data-attachments" => "1",
                               "file_0" => form_file },
                          "multipart/form-data",
                          "charset" => "UTF-8")
          end

          request
        end
      # rubocop:enable Metrics/MethodLength
    end
end
