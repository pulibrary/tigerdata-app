# frozen_string_literal: true
class XmlElementBuilder < XmlNodeBuilder
  attr_reader :presenter, :name, :attributes, :content
  alias entry content
  delegate :blank?, to: :content

  # @return [Nokogiri::XML::Element] the XML element node
  def element
    @element ||= begin
                   created = @document.create_element(name)
                   @document.root = created
                   created
                 end
  end

  # @return [Nokogiri::XML::Element] the XML element node
  def build_attributes
    attributes.each do |key, attr_entry|
      value = attr_entry
      if attr_entry.is_a?(Hash) && attr_entry.key?(:object_method)
        allow_empty_attr = attr_entry.fetch(:allow_empty, true)

        message = attr_entry[:object_method]
        method_args = attr_entry[:args] || []
        method_args = @default_method_args + method_args
        value = presenter.send(message, *method_args)

        raise ArgumentError, "Value for #{key} cannot be nil" if value.nil? && !allow_empty_attr
      end

      element[key] = value unless value.nil?
    end

    element
  end

  # @return [String] the content for the XML element
  def build_content!
    allow_empty_content = entry.fetch(:allow_empty, true)

    message = entry[:object_method]
    method_args = entry[:args] || []
    method_args = @default_method_args + method_args
    @content = presenter.send(message, *method_args)

    raise ArgumentError, "Content for #{name} cannot be nil" if content.nil? && !allow_empty_content
    content
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  #
  # @return [Nokogiri::XML::Element]
  def build
    if entry.is_a?(Hash) && entry.key?(:object_method)
      build_content!
    end

    built = build_attributes
    built.content = content

    built
  rescue ArgumentError => arg_error
    Rails.logger.warn("Error building XML project metadata: #{arg_error.message}")
    nil
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  # @return [Nokogiri::XML::Element] the XML element node
  def node
    @node ||= build
  end

  def add_child(child)
    return if child.nil?

    # @see https://nokogiri.org/rdoc/Nokogiri/XML/Node.html#method-i-clone
    level = 1
    cloned = child.clone(level, document)
    node.add_child(cloned)

    cloned
  end

  # @param [ProjectXmlPresenter] presenter
  # @param [String] name
  # @param [Hash] attributes
  # @param [String] content
  # @param [Integer] index the index for the element (when there are multiple sibling nodes)
  # @param [Hash] options
  def initialize(presenter:, name:, attributes: {}, content: nil, index: nil, **options)
    super(**options)

    @presenter = presenter
    @name = name

    @attributes = attributes
    @content = content

    @index = index

    @default_method_args = []
    @default_method_args << @index unless @index.nil?
  end
end
