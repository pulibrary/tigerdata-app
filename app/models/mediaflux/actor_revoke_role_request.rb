# frozen_string_literal: true
module Mediaflux
  class ActorRevokeRoleRequest < Request
    # Constructor
    # @param session_token [String] the API token for the authenticated session
    def initialize(session_token:, user:, type:, role:)
      super(session_token: session_token)
      @user = user
      @type = type
      @uid = user.uid

      @user_name = "princeton:#{@uid}"
      @role_name = role
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "actor.revoke"
      # "actor.revoke :type user :name princeton:[netid]] :role -type role pu-lib:developer"
    end

    def roles
      xml_roles = response_xml.xpath("/response/reply/result")
      xml_roles.map(&:text).sort
    end

  private

    #
    def build_http_request_body(name:)
      super do |xml|
        xml.args do
          xml.type @type # e.g. :type user
          xml.name @user_name # e.g. princeton:jsmith
          xml.role @role do # e.g. :role
            xml.parent.set_attribute("type", "role") # e.g. -type role
            xml.text(@role_name) # e.g. pu-lib:developer
          end
        end
      end
    end
  end
end
