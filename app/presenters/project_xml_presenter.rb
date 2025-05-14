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

      document
    end

    def initialize(document: nil)
      @document = document || build_document

      @node = nil
    end
  end

  class XmlElementBuilder < XmlNodeBuilder
    attr_reader :name, :attributes, :content

    def build
      super

      element = document.create_element(name)
      attributes.each do |key, value|
        element[key] = value
      end
      element.content = content

      @node = element
    end

    def initialize(name:, attributes: {}, content: nil, **kwargs)
      super(**kwargs)

      @name = name
      @attributes = attributes
      @content = content
    end
  end

  class XmlTreeBuilder < XmlNodeBuilder
    attr_reader :parent, :children

    def initialize(parent:, children:, **kwargs)
      @parent = parent.build
      super(document: @parent.document, **kwargs)
      document.root = @parent

      @children = children
      @children.each do |child|
        child.document = document
      end
    end

    def build
      super

      nodes = children.map(&:build)
      nodes.each do |child|
        parent.add_child(child)
      end

      @node = parent
    end
  end

  # Delegate methods to the project and project_metadata objects
  delegate "id", "in_mediaflux?", "mediaflux_id", "pending?", "status", "title", to: :project
  delegate "description", "project_id", "storage_performance_expectations", "project_purpose", to: :project_metadata

  attr_reader :project, :project_metadata

  def initialize(project)
    @project = project
    @project_metadata = @project.metadata_model
  end

  def document
    @document ||= xml_builder.build.document
  end
  alias to_xml document

  private

    #  delegate "mediaflux_id", "status",  to: :project
    #  delegate "storage_performance_expectations", to: :project_metadata

    def storage_performance_requested_content
      storage_performance_expectations[:requested]
    end

    def storage_performance_requested_node
      XmlElementBuilder.new(
        document: storage_performance_node.document,
        name: "requestedValue",
        content: storage_performance_requested_content
      )
    end

    def storage_performance_children
      [
        storage_performance_requested_node
      ]
    end

    def storage_performance_node
      XmlElementBuilder.new(
        name: "storagePerformance",
        attributes: {
          "approved" => "true",
          "inherited" => "false",
          "discoverable" => "false",
          "trackingLevel" => "InternalUseOnly"
        }
      )
    end

    def storage_performance_tree
      @storage_performance_tree ||= XmlTreeBuilder.new(
        document: root_node.document,
        parent: storage_performance_node,
        children: storage_performance_children
      )
      # <storagePerformance approved="true" inherited="true" discoverable="false" trackingLevel="InternalUseOnly">
      #        <storagePerformanceSetting>Eco</storagePerformanceSetting>
      #        <requestedValue>Eco</requestedValue>
      #        <approvedValue>Eco</approvedValue>
      #    </storagePerformance>
    end

    def project_purpose_node
      XmlElementBuilder.new(
        document: root_node.document,
        name: "projectPurpose",
        attributes: {
          "inherited" => "false",
          "discoverable" => "true",
          "trackingLevel" => "InternalUseOnly"
        },
        content: project_purpose
      )
    end

    def description_node
      # <description xml:lang="en" inherited="false" discoverable="true" trackingLevel="ResourceRecord">This is just an example description.</description>
      XmlElementBuilder.new(
        document: root_node.document,
        name: "description",
        attributes: {
          "inherited" => "false",
          "discoverable" => "true",
          "trackingLevel" => "ResourceRecord"
        },
        content: description
      )
    end

    def title_node
      # <title xml:lang="en" inherited="false" discoverable="true" trackingLevel="ResourceRecord">Example Title</title>
      XmlElementBuilder.new(
        document: root_node.document,
        name: "title",
        attributes: {
          "inherited" => "false",
          "discoverable" => "true",
          "trackingLevel" => "ResourceRecord"
        },
        content: title
      )
    end

    def project_id_node
      # <projectID projectIDType="DOI" inherited="false" discoverable="true" trackingLevel="ResourceRecord">10.34770/az09-0004</projectID>
      @project_id_node ||= XmlElementBuilder.new(
        document: root_node.document,
        name: "projectID",
        attributes: {
          "projectIDType" => "DOI",
          "inherited" => "false",
          "discoverable" => "true",
          "trackingLevel" => "ResourceRecord"
        },
        content: project_id
      )
    end

    def child_nodes
      [
        storage_performance_tree,
        project_purpose_node,
        description_node,
        title_node,
        project_id_node
      ]
    end

    def root_node
      @root_node ||= XmlElementBuilder.new(
        name: "resource",
        attributes: {
          "resourceClass" => "Project",
          "resourceID" => project_id,
          "resourceIDType" => "DOI"
        }
      )
    end

    def xml_builder
      @xml_builder ||= XmlTreeBuilder.new(
        parent: root_node,
        children: child_nodes
      )
    end
    ##

    def xml_version
      "1.0"
    end

    def xml_document_args
      [
        xml_version
      ]
    end

    def build_xml_document
      Nokogiri::XML::Document.new(*xml_document_args)
    end
end
