# frozen_string_literal: true
class XmlElementBuilder < XmlNodeBuilder
  attr_reader :presenter, :name, :allow_empty, :attributes, :content

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

      unless element.nil?
        if !allow_empty && value.nil?
          element = nil
        else
          element[key] = value
        end
      end
    end

    if content.is_a?(Hash) && content.key?(:object_method)
      entry = content
      message = entry[:object_method]
      method_args = entry[:args] || []
      method_args = default_method_args + method_args
      content = presenter.send(message, *method_args)

      if !allow_empty && content.blank?
        element = nil
      end
    end

    unless element.nil?
      element.content = content
    end

    @node = element
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  # @param [ProjectXmlPresenter] presenter
  # @param [String] name
  # @param [Boolean] allow_empty whether to allow empty elements (default: true)
  # @param [Hash] attributes
  # @param [String] content
  # @param [Integer] index the index for the element (when there are multiple sibling nodes)
  # @param [Hash] kwargs
  def initialize(presenter:, name:, allow_empty: true, attributes: {}, content: nil, index: nil, **kwargs)
    super(**kwargs)

    @presenter = presenter
    @name = name
    @allow_empty = allow_empty
    @attributes = attributes
    @content = content

    @index = index
  end
end
