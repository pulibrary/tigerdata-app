# frozen_string_literal: true
class ProjectMediaflux
  def self.create!(project:, session_id:, created_by:)
    store_name = Store.default(session_id: session_id).name
    project_name = safe_name(project.directory)
    project_namespace = "#{Rails.configuration.mediaflux['api_root_ns']}/#{project_name}-ns"
    tigerdata_values = project_values(project, created_by)

    # Create a namespace for the project
    # The namespace is directly under our root namespace
    Mediaflux::Http::NamespaceCreateRequest.new(namespace: project_namespace, description: "Namespace for project #{project.title}", store: store_name, session_token: session_id).resolve

    # Create a collection asset under the new namespace and set its metadata
    create_request = Mediaflux::Http::CreateAssetRequest.new(session_token: session_id, namespace: project_namespace, name: project_name, tigerdata_values: tigerdata_values)
    create_request.resolve
    create_request.id
  end

  def self.project_values(project, created_by)
    {
      code: project.directory,
      title: project.metadata[:title],
      description: project.metadata[:description],
      data_sponsor: project.metadata[:data_sponsor],
      data_manager: project.metadata[:data_manager],
      departments: project.metadata[:departments],
      created_on: "now",
      created_by: created_by
    }
  end

  def self.safe_name(name)
    # only alphanumeric characters
    name.strip.gsub(/[^A-Za-z\d]/, "-")
  end
end
