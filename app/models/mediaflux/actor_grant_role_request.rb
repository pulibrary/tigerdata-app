# frozen_string_literal: true
module Mediaflux
  class ActorGrantRoleRequest < Request
    attr_reader :namespace, :asset_name, :collection

    # TODO: remove this class when closing https://github.com/pulibrary/tigerdata-app/issues/1652

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param type [String] the type of the name (role or user)
    # @param type [String] the name of the user or role that will be granted the new rights
    # @param type [String] the role to grant to the user or role
    def initialize(session_token:, type:, name:, role:)
      super(session_token: session_token)
      @type = type
      @name = name
      @role = role
    end

    # Specifies the Mediaflux service to use when creating assets
    # @return [String]
    def self.service
      "actor.grant"
    end

    private

      # actor.grant :type role :name pu-lib:developer :role -type role system-administrator
      # actor.grant :type user :name princeton:hc8719 :role -type role system-administrator
      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.type @type
            xml.name @name
            xml.role do
              xml.parent.set_attribute("type", "role")
              xml.text(@role)
            end
          end
        end
      end
  end
end
