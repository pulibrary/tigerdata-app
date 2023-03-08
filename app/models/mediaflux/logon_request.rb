# frozen_string_literal: true
module Mediaflux
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

    def login
      response = build_request("system.logon") do |xml|
        xml.args do
          xml.domain Rails.configuration.mediaflux["api_domain"]
          xml.user Rails.configuration.mediaflux["api_user"]
          xml.password Rails.configuration.mediaflux["api_password"]
        end
      end

      Rails.logger.debug response.body
      doc = Nokogiri::XML.parse(response.body)
      Rails.logger.debug doc
      doc.xpath("response/reply/result/session").text
    end

    def response_session_element
      response_document.xpath("response/reply/result/session")
    end

    def response_session_token
      response_session_element.text
    end

    def resolve
      @session_token = nil
      super
      @session = response_session_token

      @http_response
    end

    private

      def build_http_request_body(name:, request_args: {})
        super(name: name, request_args: request_args) do |xml|
          xml.args do
            xml.domain mediaflux_domain
            xml.user mediaflux_user
            xml.password mediaflux_password
          end
        end
      end
  end
end
