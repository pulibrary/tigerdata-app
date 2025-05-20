# frozen_string_literal: true
class XmlTreeBuilder < XmlNodeBuilder
  attr_reader :parent, :children

  # @return [Nokogiri::XML::Element]
  def build
    super

    nodes = children.map(&:build)
    nodes.each do |child|
      parent.add_child(child)
    end
    document.root = parent

    @node = document.root
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
        multiple = child_args[:multiple] || false

        if multiple
          message = child_args[:object_method]

          method_args = child_args[:args] || []
          instances = @parent_builder.presenter.send(message, *method_args)
        end

        instances.each_with_index.map do |_instance, i|
          builder_args = child_args.dup
          builder_args[:presenter] = @parent_builder.presenter
          builder_args[:document] = document

          if multiple
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

  # @param [Array<XmlNodeBuilder>] builder objects for the child nodes in the XML tree
  # @param [Hash] kwargs
  def initialize(children: [], **kwargs)
    @parent_builder = XmlElementBuilder.new(**kwargs)
    @parent = @parent_builder.build

    super(document: @parent.document)

    @children = parse_child_entries(children)
  end
end
