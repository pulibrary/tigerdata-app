# frozen_string_literal: true

class ProjectMetadata
  DOI_NOT_MINTED = "DOI-NOT-MINTED"

  # @return [String] The default directory protocol
  def self.default_directory_protocol
    "NFS"
  end

  # @return [String] The default project resource type
  def self.default_resource_type
    "TigerData Project"
  end

  # @return [String] The default HPC value
  def self.default_hpc
    "No"
  end

  # @return [String] The default project visibility
  def self.default_project_visibility
    "Restricted"
  end

  # @return [String] The default data use agreement
  def self.default_data_use_agreement
    "No"
  end

  # @return [Hash] The default globus request Hash entries
  def self.default_globus_request
    "No"
  end

  # @return [Hash] The default Samba/SMB request Hash entries
  def self.default_smb_request
    "No"
  end

  # @return [Boolean] The default value for whether a project is provisional
  def self.default_provisionality
    false
  end

  # Ensure that the project directory is a valid path
  def self.safe_directory(directory)
    return "" if directory.nil?

    # only alphanumeric characters, underscores, and /
    directory.strip.gsub(/[^A-Za-z\d_\/]/, "-")
  end

  attr_accessor(
    :title, :description, :status, :data_sponsor, :data_manager, :departments, :data_user_read_only, :data_user_read_write,
    :created_on, :created_by, :project_id, :project_directory, :project_purpose, :storage_capacity, :storage_performance_expectations,
    :updated_by, :updated_on, :approval_note, :schema_version, :submission, :data_security_level,
    # NOTE: The following attributes are required by the XML schema
    :hpc,
    :data_use_agreement,
    :project_visibility,
    :resource_type,
    :project_directory_protocol,
    :globus_request,
    :smb_request,
    :number_of_files,
    :provisional
  )

  def initialize
    @departments = []
    @data_user_read_only = []
    @data_user_read_write = []
  end

  def self.new_from_hash(metadata_hash)
    pm = ProjectMetadata.new
    pm.initialize_from_hash(metadata_hash)
    pm
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def initialize_from_hash(metadata_hash)
    @title = metadata_hash[:title]
    @description = metadata_hash[:description]
    @status = metadata_hash[:status] if metadata_hash[:status]
    @data_sponsor = metadata_hash[:data_sponsor]
    @data_manager = metadata_hash[:data_manager]
    @departments = metadata_hash[:departments]
    @data_user_read_only = metadata_hash[:data_user_read_only] if metadata_hash[:data_user_read_only]
    @data_user_read_write = metadata_hash[:data_user_read_write] if metadata_hash[:data_user_read_write]

    @project_id = metadata_hash[:project_id] || ProjectMetadata::DOI_NOT_MINTED
    @project_purpose = metadata_hash[:project_purpose]
    @project_directory = ProjectMetadata.safe_directory(metadata_hash[:project_directory])

    @storage_capacity = metadata_hash[:storage_capacity]
    @storage_performance_expectations = metadata_hash[:storage_performance_expectations]

    @created_by = metadata_hash[:created_by] if metadata_hash[:created_by]
    @created_on = metadata_hash[:created_on] if metadata_hash[:created_on]
    @updated_by = metadata_hash[:updated_by] if metadata_hash[:updated_by]
    @updated_on = metadata_hash[:updated_on] if metadata_hash[:updated_on]

    # NOTE: The following attributes are required by the 0.8 XML schema
    @number_of_files = metadata_hash[:number_of_files] || "Less than 10,000"
    @hpc = metadata_hash[:hpc] || self.class.default_hpc
    @globus_request = metadata_hash[:globus] || metadata_hash[:globus_request] || self.class.default_globus_request
    @smb_request = metadata_hash[:smb] || metadata_hash[:smb_request] || self.class.default_smb_request

    @data_use_agreement = metadata_hash[:data_use_agreement] || self.class.default_data_use_agreement

    @project_visibility = metadata_hash[:project_visibility] || self.class.default_project_visibility
    @resource_type = metadata_hash[:resource_type] || self.class.default_resource_type

    @provisional = metadata_hash[:provisional] || self.class.default_provisionality

    @data_security_level = metadata_hash[:data_security_level] # no default is set for security level

    @submission = metadata_hash[:submission]
    @schema_version = metadata_hash[:schema_version] || TigerdataSchema::SCHEMA_VERSION
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  # Alias for `data_user_read_only`
  def ro_users
    @data_user_read_only
  end

  # Alias for `data_user_read_write`
  def rw_users
    @data_user_read_write
  end

  def doi_path
    project_id.tr("/", "-")
  end

  # Write-through from Mediaflux quota into the approved storage_capacity fields.
  # Preserves requested size/unit (wizard / import history).
  def apply_approved_quota(size:, unit:)
    current = (@storage_capacity || {}).deep_dup.with_indifferent_access
    @storage_capacity = {
      "size" => {
        "approved" => size,
        "requested" => current.dig(:size, :requested)
      },
      "unit" => {
        "approved" => unit,
        "requested" => current.dig(:unit, :requested)
      }
    }
  end
end
