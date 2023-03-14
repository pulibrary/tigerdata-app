# frozen_string_literal: true
module Mediaflux
  class Collection
    # Specifies the default attributes for every Collection within Mediaflux
    # @return [Hash]
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

    # Constructs a new Collection from an XML document, fragment, or element provided by the Mediaflux server
    # @param node [Nokogiri::XML::Node] any XML document, fragment, or element parsed from the Mediaflux server response
    # @return [Collection]
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

    # Constructs all Collections from an XML document, fragment, or element provided by the Mediaflux server
    # @param xml [Nokogiri::XML::Node] any XML document, fragment, or element parsed from the Mediaflux server response
    # @return [Array<Collection>]
    def self.build_from_response(xml:)
      response_element = xml.at_xpath("/response")
      reply_element = response_element.at_xpath("reply")
      result_element = reply_element.at_xpath("result")

      collection_elements = result_element.xpath("collection")
      collection_elements.map { |e| build_from_xml(node: e) }
    end

    attr_reader :type, :id, :children

    # Constructor
    # @param type [String] the type of the Mediaflux collection
    # @param id [String] the ID within the Mediaflux server
    # @param children [Array<Collection>] the set of collections for which this is a parent node
    # @param attributes [Hash] any additional attributes provided for the collection
    def initialize(type:, id:, children: [], **attributes)
      @type = type
      @id = id
      @children = children
      @attributes = self.class.default_attributes.merge(attributes)
    end
  end
end
