# frozen_string_literal: true
module Mediaflux
  class SchemaFetchRequest < Request
    def self.service
      "asset.doc.type.describe"
    end

    def initialize(namespace:, type:, session_token:)
      super(session_token: session_token)
      @namespace = namespace
      @type = type
    end

    def fields
      elements = response_xml.xpath("/response/reply/result/type/definition/element")
      elements.map { |element| field_from_element(element) }
    end

    private

      def build_http_request_body(name:)
        super(name: name) do |xml|
          xml.args do
            xml.namespace @namespace
            xml.type @type
          end
        end
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def field_from_element(element)
        field = {
          name: element.attributes["name"].value,
          type: element.attributes["type"].value,
          index: element.attributes["index"]&.value == "true",
          "min-occurs" => 1,
          label: element.attributes["label"].value,
          description: element.xpath("description").text,
          instructions: element.xpath("instructions").text
        }

        if element.attributes["min-occurs"].present?
          field["min-occurs"] = element.attributes["min-occurs"].value.to_i
        end

        if element.attributes["max-occurs"].present?
          field["max-occurs"] = element.attributes["max-occurs"].value.to_i
        end

        field
      end
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
  end
end
