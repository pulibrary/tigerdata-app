# frozen_string_literal: true
class ProjectMediaflux
  def self.create!(project:, session_id:, created_by:)
    store_name = Store.default(session_id: session_id).name

    # Make sure the root namespace exists
    create_root_ns(session_id: session_id)

    # Create a namespace for the project
    # The namespace is directly under our root namespace
    project_name = safe_name(project.directory)
    project_namespace = "#{Rails.configuration.mediaflux['api_root_ns']}/#{project_name}-ns"
    Mediaflux::Http::NamespaceCreateRequest.new(namespace: project_namespace, description: "Namespace for project #{project.title}", store: store_name, session_token: session_id).resolve

    # Create a collection asset under the new namespace and set its metadata
    tigerdata_values = project_values(project: project, created_by: created_by)
    create_request = Mediaflux::Http::CreateAssetRequest.new(session_token: session_id, namespace: project_namespace, name: project_name, tigerdata_values: tigerdata_values)
    create_request.resolve
    create_request.id
  end

  def self.update(project:, session_id:, updated_by:)
    tigerdata_values = project_values(project: project, updated_by: updated_by)
    Mediaflux::Http::UpdateAssetRequest.new(session_token: session_id, id: project.mediaflux_id, tigerdata_values: tigerdata_values).resolve
  end

  # rubocop:disable Metrics/MethodLength
  def self.project_values(project:, created_by: nil, updated_by: nil)
    values = {
      code: project.directory,
      title: project.metadata[:title],
      description: project.metadata[:description],
      data_sponsor: project.metadata[:data_sponsor],
      data_manager: project.metadata[:data_manager],
      data_user_read_only: project.metadata[:data_user_read_only],
      data_user_read_write: project.metadata[:data_user_read_write],
      departments: project.metadata[:departments]
    }

    if created_by
      values[:created_on] = "now"
      values[:created_by] = created_by
    end

    if updated_by
      values[:updated_on] = "now"
      values[:updated_by] = updated_by
    end

    values
  end
  # rubocop:enable Metrics/MethodLength

  def self.safe_name(name)
    # only alphanumeric characters
    name.strip.gsub(/[^A-Za-z\d]/, "-")
  end

  def self.create_root_ns(session_id:)
    root_namespace = Rails.configuration.mediaflux["api_root_ns"]
    namespace_request = Mediaflux::Http::NamespaceDescribeRequest.new(path: root_namespace, session_token: session_id)
    if namespace_request.exists?
      Rails.logger.info "Root namespace #{root_namespace} already exists"
    else
      Rails.logger.info "Created root namespace #{root_namespace}"
      namespace_request = Mediaflux::Http::NamespaceCreateRequest.new(namespace: root_namespace, description: "TigerData client app root namespace",
                                                                      store: Store.all(session_id: session_id).first.name,
                                                                      session_token: session_id)
      namespace_request.response_body
    end
  end
end
