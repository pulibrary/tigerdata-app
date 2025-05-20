# frozen_string_literal: true
class XmlElementBuilder < XmlNodeBuilder
  attr_reader :presenter, :name, :attributes, :content

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  #
  # @return [Nokogiri::XML::Element]
  def build
    super

    element = document.create_element(name)

    default_method_args = []
    default_method_args << @index unless @index.nil?

    attributes.each do |key, entry|
      value = entry
      if entry.is_a?(Hash) && entry.key?(:object_method)
        message = entry[:object_method]
        method_args = entry[:args] || []
        method_args = default_method_args + method_args
        value = presenter.send(message, *method_args)
      end

      element[key] = value
    end

    if content.is_a?(Hash) && content.key?(:object_method)
      entry = content
      message = entry[:object_method]
      method_args = entry[:args] || []
      method_args = default_method_args + method_args
      content = presenter.send(message, *method_args)
    end

    element.content = content

    @node = element
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  # @param [ProjectXmlPresenter] presenter
  # @param [String] name
  # @param [Hash] attributes
  # @param [String] content
  # @param [Integer] index the index for the element (when there are multiple sibling nodes)
  # @param [Hash] kwargs
  def initialize(presenter:, name:, attributes: {}, content: nil, index: nil, **kwargs)
    super(**kwargs)

    @presenter = presenter
    @name = name
    @attributes = attributes
    @content = content

    @index = index
  end
end
