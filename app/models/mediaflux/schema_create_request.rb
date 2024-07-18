# frozen_string_literal: true
module Mediaflux
  class SchemaCreateRequest < Request
    attr_reader :name, :description

    # Mediaflux service to use to define a new namespace
    # We use "asset.doc.namespace.update" instead of "asset.doc.namespace.create"
    # because update is more forgiving if the asseet.doc.namespace already exists
    def self.service
      "asset.doc.namespace.update"
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
            xml.create true
            xml.namespace @name
            xml.description @description
          end
        end
      end
  end
end
