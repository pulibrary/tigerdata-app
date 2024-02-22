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

        def build_http_request_body(name:)
          super(name: name) do |xml|
            xml.args do
              xml.create true
              xml.description @description
              xml.type "#{@schema_name}:#{@document}"
              xml.definition do
                @fields.each do |field|
                  build_field(xml:, field:)
                end
              end
            end
          end
        end

        def build_field(xml:, field:)
          attributes =  field.delete(:attributes)
          xml.element(field) do
            if attributes.present?
              attributes.each do |attribute|
                xml.attribute(attribute)
              end
            end
          end
        end
    end
  end
end
