# frozen_string_literal: true
module Mediaflux
  class PackageDescribeRequest < Request
    attr_reader :token, :service_name, :document

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param package_name  [String] The name of the Mediaflux package to describe
    def initialize(session_token:, package_name:)
      super(session_token: session_token)
      @package_name = package_name
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "package.describe"
    end

    # Returns the quota information for collection in Mediaflux
    def describe
      result = response_xml.xpath("response/reply/result")
      {
        version: result.xpath("package/version").text,
        description: result.xpath("package/version").text
      }
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.package @package_name
          end
        end
      end
  end
end
