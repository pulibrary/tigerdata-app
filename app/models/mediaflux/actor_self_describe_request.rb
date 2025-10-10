# frozen_string_literal: true
module Mediaflux
  class ActorSelfDescribeRequest < Request
    # Constructor
    # @param session_token [String] the API token for the authenticated session
    def initialize(session_token:)
      super(session_token: session_token)
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "actor.self.describe"
    end

    def roles
      xml_roles = response_xml.xpath("/response/reply/result/actor/role[@type='role']")
      xml_roles.map(&:text).sort
    end
  end
end
