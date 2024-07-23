# frozen_string_literal: true
module Mediaflux
  class NamespaceCreateRequest < Request
    attr_reader :description, :namespace, :store

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param namespace [String] name of namespace to be created
    # @param decsription [String] Optional description of the namespace
    # @param store [String] Optional store name where the namespace will be attached
    def initialize(session_token:, namespace:, description: nil, store: nil)
      super(session_token: session_token)
      @namespace = namespace
      @description = description
      @store = store
    end

    # Specifies the Mediaflux service to use when creating assets
    # @return [String]
    def self.service
      "asset.namespace.create"
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            if namespace.present?
              xml.namespace do
                xml.parent.set_attribute("all", true)
                xml.text(namespace)
              end
            end
            xml.description description if description.present?
            xml.store store if store.present?
          end
        end
      end
  end
end
