# frozen_string_literal: true
module Mediaflux
  class TokenCreateRequest < Request
    # Specifies the logon service within the Mediaflux API
    # @return [String]
    def self.service
      "secure.identity.token.create"
    end

    def initialize(session_token:, domain:, user:)
      @domain = domain
      @user = user
      super(session_token: session_token)
    end

    def identity
      @id ||= response_xml.xpath("/response/reply/result/token").text.strip
      @id
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.identity do
              xml.send("grant-user-roles", true)
              xml.domain @domain
              xml.user @user
            end
          end
        end
      end
  end
end
