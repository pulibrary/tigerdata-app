# frozen_string_literal: true

class XmlNullBuilder < XmlNodeBuilder
  def build
    document
  end

  def blank?
    true
  end

  # No-op for null builder
  def add_child(_child)
    nil
  end

  def name
    nil
  end

  def initialize(**_options)
    super(document: nil)
  end
end

class XmlTreeBuilder < XmlNodeBuilder
  attr_reader :children, :root_builder_options

  def null_builder
    @null_builder ||= XmlNullBuilder.new(**root_builder_options)
  end

  def root_builder
    @root_builder ||= begin
                        default_builder = XmlElementBuilder.new(**root_builder_options)
                        null_builder if default_builder.blank?
                        default_builder
                      end
  end

  delegate :node, :document, to: :root_builder

  # @return [Nokogiri::XML::Element]
  def build
    nodes = children.map(&:build)
    nodes.each do |child|
      root_builder.add_child(child)
    end

    node
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  #
  # @param [Array<Hash>] entries options for constructing each child node
  # @return [Array<Nokogiri::XML::Node>] an array of XML child nodes
  def parse_child_entries(entries)
    instances = [:default]
    builders = entries.map do |child_entry|
      child_entry.values.map do |child_args|
        multiple_children = child_args[:multiple] || false

        if multiple_children
          message = child_args[:object_method]

          method_args = child_args[:args] || []
          instances = root_builder.presenter.send(message, *method_args)
        end

        instances.each_with_index.map do |_instance, i|
          builder_args = child_args.dup
          builder_args[:presenter] = root_builder.presenter
          builder_args[:document] = document

          if multiple_children
            builder_args[:index] = i
            builder_args.delete(:multiple)
          end
          builder_args.delete(:object_method)
          builder_args.delete(:args)
          self.class.new(**builder_args)
        end
      end
    end
    builders.flatten
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  # @param children [Array<XmlNodeBuilder>] XmlNodeBuilder objects for the child nodes in the XML tree
  # @param options [Hash] arguments for the root XmlElementBuilder
  def initialize(children: [], **options)
    @root_builder_options = options.dup
    @children = parse_child_entries(children)

    super(document: document)
  end
end
