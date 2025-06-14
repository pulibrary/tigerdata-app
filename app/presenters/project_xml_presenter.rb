# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class ProjectXmlPresenter
  attr_reader :project, :project_metadata

  # Delegate methods to the project and project_metadata objects
  delegate(
    "id",
    "in_mediaflux?",
    "mediaflux_id",
    "pending?",
    "title",
    to: :project
  )

  delegate(
    "approval_note",
    "description",
    "data_manager",
    "data_sponsor",
    "data_user_read_only",
    "data_user_read_write",
    "departments",
    "project_id",
    "project_purpose",
    "storage_capacity",
    "storage_performance_expectations",
    "created_by",
    "created_on",
    "updated_by",
    "updated_on",
    "schema_version",
    to: :project_metadata
  )

  # @param project [Project] The project for the presenter
  def initialize(project)
    @project = project
    @project_metadata = @project.metadata_model
  end

  # @return [Nokogiri::XML::Document] The XML document
  delegate :document, to: :build

  # @return [Boolean] Whether the request for a Globus mount is approved
  def globus_enable_approved?
    globus_request = project_metadata.globus_request
    globus_request[:approved] || false
  end

  # @return [String] Whether the request for a Globus mount is approved
  def globus_enable_approved
    if globus_enable_approved?
      "true"
    else
      "false"
    end
  end

  # @return [Boolean] Whether there is a request for a Globus mount
  def globus_enable_requested?
    globus_request = project_metadata.globus_request
    globus_request.present?
  end

  # @return [String] Whether the request for a Globus mount is requested
  def globus_enable_requested
    if globus_enable_requested?
      "true"
    else
      "false"
    end
  end

  # @return [Boolean] Whether the request for the SMB mount is approved
  def smb_enable_approved?
    smb_request = project_metadata.smb_request
    smb_request[:approved] || false
  end

  # @return [String] Whether the request for the SMB mount is approved
  def smb_enable_approved
    if smb_enable_approved?
      "true"
    else
      "false"
    end
  end

  # @return [Boolean] Whether there is a request for SMB mount
  def smb_enable_requested?
    smb_request = project_metadata.smb_request
    smb_request.present?
  end

  # @return [String] Whether the request for the SMB mount is requested
  def smb_enable_requested
    if smb_enable_requested?
      "true"
    else
      "false"
    end
  end

  # @return [String] The project status (mapped to values specified by the TigerData XML schema)
  # NOTE: Valid values are one of: 'AdminReview', 'Approved', 'Active', 'Retired', 'Published'
  def status
    project_status = project.status
    return if project_status.nil?

    return "AdminReview" if project_status == Project::PENDING_STATUS

    project_status.capitalize
  end

  # @return [ProvenanceEvent] The first project submission event
  def submission
    @submission ||= project.provenance_events.find_by(event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE)
  end

  # @return [Array<ProvenanceEvent>] The project submission events
  def submissions
    [submission]
  end

  # @return [String] The user ID of the user who requested the project
  def requested_by
    return if submission.nil?

    submission.event_person
  end

  # @return [String] The date and time of the request
  def request_date_time
    return if submission.nil?

    value = submission.created_at
    value.strftime("%Y-%m-%dT%H:%M:%S%:z")
  end

  # @return [String] The user ID of the user who approved the project
  def approved_by
    return if approval_note.nil?

    approval_note[:note_by]
  end

  # @return [String] The date and time of the approval
  def approval_date_time
    return nil if approval_note.nil?

    approval_note[:note_date_time]
  end

  # @return [String] Whether or not the project data use agreement
  def data_use_agreement?
    project_metadata.data_use_agreement.present?
  end

  # @return [String] The project resource type
  def project_resource_type
    project_metadata.resource_type
  end

  # @return [Boolean] Whether the project is provisional
  def provisional_project?
    project_metadata.provisional
  end

  # @return [String] Whether or not the project is associated with HPC
  delegate :hpc, to: :project_metadata

  # @return [String] The project visibility
  delegate :project_visibility, to: :project_metadata

  # @return [Boolean] Whether the project directory request is approved
  def project_directory_approved?
    expectations = storage_performance_expectations
    expectations[:approved] || false
  end

  # @return [Boolean] Whether the project storage capacity request is approved
  def storage_capacity_approved?
    storage_capacity_size = storage_capacity["size"] || {}
    return false unless storage_capacity_size.key?(:approved)

    approved_size = storage_capacity_size[:approved] || 0
    approved_size > 0
  end

  # @return [Boolean] Whether the project storage request is approved
  def storage_performance_requested?
    requested = storage_performance_expectations[:requested]
    requested.present?
  end

  # @return [Array<String>] The project directory paths
  def project_directory
    [project.project_directory]
  end

  # @param index [Integer] The index of the project directory
  # @return [String] The project directory path
  def project_directory_path(index)
    entry = project_directory[index]
    entry
  end

  # @param index [Integer] The index of the project directory
  # @return [String] The protocol for the project directory
  def project_directory_protocol(index)
    entry = project_directory[index]
    segments = entry.split("://")

    if segments.length > 1
      value = segments[0]
      value.upcase
    else
      ProjectMetadata.default_directory_protocol
    end
  end

  # @param index [Integer] The index of the department code to retrieve
  # @return [String] The department code for departments associated with the project
  def department(index)
    value = departments[index]
    if value.length < 6
      value = value.rjust(6, "0")
    end
    value
  end

  # @return [String] The department code for the project
  def department_code(index)
    departments[index]
  end

  # @return [String] The requested project storage capacity
  def requested_storage
    storage_performance_expectations[:requested] || nil
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

    def builder
      @builder ||= begin
                     builder_args = find_builder_args(:resource)
                     XmlTreeBuilder.new(**builder_args)
                   end
    end

    delegate :build, to: :builder
end
# rubocop:enable Metrics/ClassLength
