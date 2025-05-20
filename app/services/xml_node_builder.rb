# frozen_string_literal: true
class XmlNodeBuilder
  attr_accessor :document

  def xml_version
    "1.0"
  end

  def xml_document_args
    [
      xml_version
    ]
  end

  def build_document
    Nokogiri::XML::Document.new(*xml_document_args)
  end

  def build
    return @node unless @node.nil?

    @node = document.root
  end

  def initialize(document: nil)
    @document = document || build_document

    @node = nil
  end
end
