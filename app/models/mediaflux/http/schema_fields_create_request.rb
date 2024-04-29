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
          dup_field = field.deep_dup
          attributes =  dup_field.delete(:attributes)
          description = dup_field.delete(:description)
          instructions = dup_field.delete(:instructions)
          sub_elements = dup_field.delete(:sub_elements) || []
          xml.element(dup_field) do
            if attributes.present?
              attributes.each do |attribute|
                attr_description = attribute.delete(:description)
                xml.attribute(attribute) do
                  xml.description attr_description
                end
              end
            end
            if description.present?
              xml.description description
            end
            if instructions.present?
              xml.instructions instructions
            end
            sub_elements.each do |field|
              build_field(xml:, field:)
            end
          end
        end
    end
  end
end
