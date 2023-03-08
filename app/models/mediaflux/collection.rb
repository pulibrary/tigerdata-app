# frozen_string_literal: true
module Mediaflux
  class Collection
    def self.build_from_xml(xml_node)
      # This needs to be moved
      reply_element = xml_node.at_xpath("/reply")
      result_element = reply_element.at_xpath("/result")

      collection_element = result_element.at_xpath("/collection")

      child_elements = collection_element.xpath("/collection")
      child_collections = child_elements.map { |e| build_from_xml(e) }
      children = child_collections

      type = collection_element["type"]
      id = collection_element["id"]

      attributes = {}
      default_attributes.keys.each do |key|
        value = collection_element[key]

        attributes[key] = value
      end

      new(type: type, id: id, children: children, **attributes)
    end

    attr_reader :session_token

    def self.default_attributes
      {
        leaf: false,
        acl: false,
        unique_name_index: true,
        create_assets: true,
        create_collections: true,
        path: nil,
        name: nil,
        children: []
      }
    end

    # Constructor
    def initialize(type:, id:, **attributes)
      @type = type
      @id = id
      @attributes = self.class.default_attributes.merge(attributes)
    end

    def children
      @attributes[:children]
    end
  end
end
