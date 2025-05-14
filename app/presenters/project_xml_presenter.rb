# frozen_string_literal: true
class ProjectXmlPresenter
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
      attributes.each do |key, entry|
        value = entry
        if entry.is_a?(Hash) && entry.key?(:message)
          message = entry[:message]
          method_args = []
          if entry.key?(:args)
            method_args = entry[:args] || []
            method_args += @message_args
          end
          value = presenter.send(message, *method_args)
        end

        element[key] = value
      end

      if content.is_a?(Hash) && content.key?(:message)
        entry = content
        message = entry[:message]
        method_args = []
        if entry.key?(:args)
          method_args = entry[:args] || []
          method_args += @message_args
        end
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

      @message_args = []
      @message_args << index unless index.nil?
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

    def initialize(children: [], **kwargs)
      parent_builder = XmlElementBuilder.new(**kwargs)
      @parent = parent_builder.build

      super(document: @parent.document)

      instances = [:default]
      builders = children.map do |entry|
        entry.values.map do |child_args|
          multiple = child_args[:multiple] || false

          if multiple
            message = child_args[:message]

            if child_args.key?(:args)
              method_args = entry[:args] || []
              instances = parent_builder.presenter.send(message, *method_args)
            else
              instances = parent_builder.presenter.send(message)
            end
          end

          instances.each_with_index.map do |_instance, i|
            child_args[:index] = i
            child_args[:presenter] = parent_builder.presenter
            child_args[:document] = document
            child_args.delete(:multiple)
            child_args.delete(:message)
            child_args.delete(:args)
            self.class.new(**child_args)
          end
        end
      end

      @children = builders.flatten
    end
  end

  # Delegate methods to the project and project_metadata objects
  delegate "id", "in_mediaflux?", "mediaflux_id", "pending?", "status", "title", to: :project
  delegate(
    "data_manager", "data_sponsor",
    "data_user_read_only", "data_user_read_write",
    "departments", "description",
    "project_directory", "project_id", "project_purpose",
    "storage_capacity", "storage_performance_expectations",
    "created_by", "created_on",
    "updated_by", "updated_on",
    to: :project_metadata
  )
  # :approval_note, :schema_version, :submission

  attr_reader :project, :project_metadata

  def initialize(project)
    @project = project
    @project_metadata = @project.metadata_model
  end

  def document
    @document ||= build.document
  end

  def storage_performance_approved?
    false
  end

  def project_directory_paths(index)
    project_directory[index]
  end

  def project_directory_protocols(index)
    project_directory[index]
  end

  private

    def department_codes(index)
      departments[index]
    end

    def requested_storage_performance
      storage_performance_expectations[:requested]
    end

    def xml_builder_config
      Rails.configuration.xml_builder
    end

    def presenter_builder_config
      xml_builder_config[:project]
    end

    def find_builder_args(key)
      values = presenter_builder_config[key]
      values[:presenter] = self
      values
    end

    def xml_builder
      @xml_builder ||= begin
                         builder_args = find_builder_args(:resource)
                         XmlTreeBuilder.new(**builder_args)
                       end
    end

    def build
      xml_builder.build
    end
end
