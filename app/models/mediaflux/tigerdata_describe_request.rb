# frozen_string_literal: true
module Mediaflux
  class TigerdataDescribeRequest < Request

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    def initialize(session_token:)
      super(session_token: session_token)
    end

    # Specifies the Mediaflux service to use when querying Mediaflux.
    # @return [String]
    def self.service
      "tigerdata.describe"
    end

    def server_values
        xml = response_xml.xpath("/response/reply/result/server")
        {
          uuid: xml.xpath("./@uuid").text,
          name: xml.xpath("./@name").text == "" ? "UNSET" : xml.xpath("./@name").text,
          server_version: xml.xpath("./server-version").text,
          tigerdata_config_version: xml.xpath("./tigerdata-config-version").text,
          tigerdata_plugin_version: xml.xpath("./tigerdata-plugin-version").text
        }
    end
  end
end
