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

class XmlElementBuilder < XmlNodeBuilder
    attr_reader :presenter, :name, :attributes, :content

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

    def initialize(presenter:, name:, attributes: {}, content: nil, index: nil, **kwargs)
    super(**kwargs)

    @presenter = presenter
    @name = name
    @attributes = attributes
    @content = content

    @index = index
    end
end

class XmlTreeBuilder < XmlNodeBuilder
    attr_reader :parent, :children

    def build
      super

      nodes = children.map(&:build)
      nodes.each do |child|
        parent.add_child(child)
      end
      document.root = parent

      @node = document.root
    end

    def parse_child_entries(entries)
      instances = [:default]
      builders = entries.map do |entry|
        entry.values.map do |child_args|
          multiple = child_args[:multiple] || false

          if multiple
            message = child_args[:object_method]

            method_args = entry[:args] || []
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