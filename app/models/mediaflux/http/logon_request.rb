# frozen_string_literal: true
module Mediaflux
  module Http
    class LogonRequest < Request
      def self.service
        "system.logon"
      end

      def self.mediaflux_domain
        mediaflux["api_domain"]
      end

      def self.mediaflux_user
        mediaflux["api_user"]
      end

      def self.mediaflux_password
        mediaflux["api_password"]
      end

      def response_session_element
        response_document.xpath("response/reply/result/session")
      end

      def response_session_token
        value = response_session_element.text
        value.strip
      end

      def resolve
        @session_token = nil
        super
        @session_token = response_session_token

        @http_response
      end

      private

        def build_http_request_body(name:, request_args: {})
          super(name: name, request_args: request_args) do |xml|
            xml.args do
              xml.domain self.class.mediaflux_domain
              xml.user self.class.mediaflux_user
              xml.password self.class.mediaflux_password
            end
          end
        end
    end
  end
end
