# frozen_string_literal: true
class XmlNodeBuilder
  XML_VERSION = "1.0"

  attr_accessor :document

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
    return unless @node.nil?

    @node = document.root
  end

  # @param [Nokogiri::XML::Document] document
  def initialize(document: nil)
    @document = document || build_document

    @node = nil
  end
end
