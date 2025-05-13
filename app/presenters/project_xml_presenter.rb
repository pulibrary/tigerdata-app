# frozen_string_literal: true
class ProjectXmlPresenter
  delegate "id", "in_mediaflux?", "mediaflux_id", "pending?", "status", "title", to: :project
  delegate "description", "project_id", "storage_performance_expectations", "project_purpose", to: :project_metadata

  attr_reader :project, :project_metadata

  def initialize(project)
    @project = project
    @project_metadata = @project.metadata_model
  end

  def document
    @document ||= root_node.document
  end
  alias to_xml document

  private

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

    def title_node
      # <title xml:lang="en"
      # inherited="false"
      # discoverable="true"
      # trackingLevel="ResourceRecord">Test Item 1</title>
      new_node = @document.create_element("title")
      # TODO: Determine how Ruby models might affect these attributes
      new_node["inherited"] = "false"
      new_node["discoverable"] = "true"
      new_node["trackingLevel"] = "ResourceRecord"
      new_node.content = title

      new_node
    end

    def root_node
      # An example root node:
      # <resource resourceClass="Project"
      # resourceID="10.34770/az09-0003"
      # resourceIDType="DOI">
      @root_node ||= begin
                       @document = build_xml_document
                       root_name = "resource"
                       root = @document.create_element(root_name)
                       @document.root = root
                       root["resourceClass"] = "Project"
                       root["resourceID"] = project_id
                       root["resourceIDType"] = "DOI"

                       root.add_child(title_node)
                       root
                     end
    end
end
