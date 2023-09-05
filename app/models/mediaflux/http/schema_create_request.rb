# frozen_string_literal: true
module Mediaflux
  module Http
    class SchemaCreateRequest < Request
      attr_reader :name, :description

      # Mediaflux service to use to define a new namespace
      # @return [String]
      def self.service
        "asset.doc.namespace.create"
      end

      def initialize(name:, description:, session_token:)
        super(session_token: session_token)
        @name = name
        @description = description
      end

      private

        def build_http_request_body(name:)
          super(name: name) do |xml|
            xml.args do
              xml.namespace @name
              xml.description @description
            end
          end
        end
    end
  end
end
