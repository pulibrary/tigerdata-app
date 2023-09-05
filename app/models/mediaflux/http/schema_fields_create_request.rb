# frozen_string_literal: true
module Mediaflux
  module Http
    class SchemaFieldsCreateRequest < Request
      attr_reader :schema_name, :document, :description, :fields

      # Mediaflux service to use to define fields in a schema namespace
      # @return [String]
      def self.service
        "asset.doc.type.update"
      end

      def initialize(schema_name:, document:, description:, fields:, session_token:)
        super(session_token: session_token)
        @schema_name = schema_name
        @document = document
        @description = description
        @fields = fields
      end

      private

        # :element -name id            -type string -index true -min-occurs 1 -max-occurs 1 -label "The unique identifier for the project" \
        def build_http_request_body(name:)
          super(name: name) do |xml|
            xml.args do
              xml.create true
              xml.description @description
              xml.type "#{@schema_name}:#{@document}"
              xml.definition do
                @fields.each do |field|
                  xml.element(name: field[:name], type: field[:type], index: field[:index] == true)
                end
              end
            end
          end
        end
    end
  end
end
