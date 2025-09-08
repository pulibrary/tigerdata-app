# frozen_string_literal: true
module Mediaflux
  class ActorSelfDescribeRequest < Request
    # Constructor
    # @param session_token [String] the API token for the authenticated session
    def initialize(session_token:, session_user: nil)
      super(session_token: session_token, session_user: session_user)
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "actor.self.describe"
    end

    def roles
      xml_roles = response_xml.xpath("/response/reply/result/actor/role[@type='role']")
      xml_roles.map { |xml_node| xml_node.text }
    end
  end
end
