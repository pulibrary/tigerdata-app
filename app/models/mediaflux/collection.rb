# frozen_string_literal: true
module Mediaflux
  class Collection
    def self.default_attributes
      {
        leaf: false,
        acl: false,
        unique_name_index: true,
        create_assets: true,
        create_collections: true,
        path: nil,
        name: nil
      }
    end

    def self.build_from_xml(node:)
      child_elements = node.xpath("collection")
      children = child_elements.map { |e| build_from_xml(node: e) }

      type = node["type"]
      id = node["id"]

      attributes = {}
      default_attributes.keys.each do |key|
        value = node[key]

        attributes[key] = value
      end

      new(type: type, id: id, children: children, **attributes)
    end

    def self.build_from_response(xml:)
      response_element = xml.at_xpath("/response")
      reply_element = response_element.at_xpath("reply")
      result_element = reply_element.at_xpath("result")

      collection_elements = result_element.xpath("collection")
      collection_elements.map { |e| build_from_xml(node: e) }
    end

    attr_reader :type, :id, :children

    # Constructor
    def initialize(type:, id:, children: [], **attributes)
      @type = type
      @id = id
      @children = children
      @attributes = self.class.default_attributes.merge(attributes)
    end
  end
end
