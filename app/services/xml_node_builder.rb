# frozen_string_literal: true
class XmlNodeBuilder
  XML_VERSION = "1.0"

  attr_reader :document, :node

  # @return [String]
  def xml_version
    XML_VERSION
  end

  # @return [Array<String>]
  def xml_document_args
    [
      xml_version
    ]
  end

  # @return [Nokogiri::XML::Document]
  def build_document
    Nokogiri::XML::Document.new(*xml_document_args)
  end

  # @return [Nokogiri::XML::Element]
  def build
    return node if node.present?

    @node = document.root
  end

  # @param [Nokogiri::XML::Document] document
  def initialize(document: nil)
    @document = document || build_document

    @node = nil
  end
end
