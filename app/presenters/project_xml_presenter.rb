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

    def initialize(children: [], **kwargs)
      @parent_builder = XmlElementBuilder.new(**kwargs)
      @parent = @parent_builder.build

      super(document: @parent.document)

      @children = parse_child_entries(children)
    end
  end

  # Delegate methods to the project and project_metadata objects
  delegate "id", "in_mediaflux?", "mediaflux_id", "pending?", "status", "title", to: :project
  delegate(
    "data_manager", "data_sponsor",
    "data_user_read_only", "data_user_read_write",
    "departments", "description",
    "project_id", "project_purpose",
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
    @document ||= build_xml.document
  end

  def globus_enable_approved?
    false
  end

  def smb_enable_approved?
    false
  end

  def schema_version
    0.8
  end

  def status
    "Active"
  end

  def provenance_submissions
    []
  end

  def data_use_agreement?
    false
  end

  def project_resource_type
    "TigerData Project"
  end

  def provisional_project?
    false
  end

  def hpc
    "No"
  end

  def project_visibility
    "Restricted"
  end

  def project_directory_approved?
    false
  end

  def storage_capacity_approved?
    false
  end

  def storage_performance_approved?
    false
  end

  def project_directory
    [project_metadata.project_directory]
  end

  def project_directory_path(index)
    entry = project_directory[index]
    entry
  end

  def project_directory_protocol(index)
    entry = project_directory[index]
    segments = entry.split("://")
    default_protocol = "NFS"

    if segments.length > 1
      segments[0]
    else
      default_protocol
    end
  end

  def department(index)
    value = departments[index]
    if value.length < 6
      value = value.rjust(6, "0")
    end
    value
  end

  def department_code(index)
    departments[index]
  end

  def requested_storage
    storage_performance_expectations[:requested]
  end

  private

    def xml_builder_config
      Rails.configuration.xml_builder
    end

    def presenter_builder_config
      xml_builder_config[:project] || {}
    end

    def find_builder_args(key)
      raise "No builder config for #{key}" unless presenter_builder_config.key?(key)

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

    def build_xml
      xml_builder.build
    end
end
