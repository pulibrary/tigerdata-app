# frozen_string_literal: true

class ProjectMetadata
  class MediafluxError < StandardError; end

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
    :updated_by, :updated_on, :approval_note, :schema_version, :submission, :data_security_level, :asset_count, :storage_usage,
    :storage_usage_raw, :quota_allocation, :quota_allocation_raw, :updated_from_mediaflux_on, :request_metadata,
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

  attr_reader :project

  delegate :id, :mediaflux_id, :created_at, :updated_at, to: :project

  def initialize(project, metadata_hash = nil)
    @project = project
    @request_metadata = project.metadata_json["request_metadata"]
    initialize_from_hash(project.metadata_json.with_indifferent_access)
    if metadata_hash.present?
      initialize_from_hash(metadata_hash)
    end
  end

  def update_project
    @project.metadata_json = JSON.parse(to_json)
    @project.save!
  end

  def update_with_mediaflux_data(session_id:)
    # make sure the request metadata that was present when the project was created is kept
    @request_metadata = project.metadata_json["request_metadata"] || project.metadata_json
    metadata = mediaflux_metadata(session_id:)
    initialize_from_hash(metadata)
    @updated_from_mediaflux_on = DateTime.now
    update_project
    metadata
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
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

    @storage_capacity = metadata_hash[:storage_capacity] if metadata_hash[:storage_capacity]
    @storage_performance_expectations = metadata_hash[:storage_performance_expectations] if metadata_hash[:storage_performance_expectations]

    @created_by = metadata_hash[:created_by] if metadata_hash[:created_by]
    @created_on = metadata_hash[:created_on] if metadata_hash[:created_on]
    @updated_by = metadata_hash[:updated_by] if metadata_hash[:updated_by]
    @updated_on = metadata_hash[:updated_on] if metadata_hash[:updated_on].present?

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

    @submission = metadata_hash[:submission] || {}
    if @submission["requested_by"].blank? && request_metadata && request_metadata["submission"]
      @submission = request_metadata["submission"]
    end
    @schema_version = metadata_hash[:schema_version] || TigerdataSchema::SCHEMA_VERSION
    @asset_count = metadata_hash[:total_file_count] || metadata_hash[:asset_count] || 0
    @storage_usage = metadata_hash[:quota_used] || metadata_hash[:storage_usage] || self.class.default_storage_usage # if the storage is empty use the default
    @storage_usage_raw = metadata_hash[:quota_used_raw] || metadata_hash[:storage_usage_raw] || 0 # if the storage raw is empty use zero
    @quota_allocation = metadata_hash.fetch(:quota_allocation, self.class.default_quota_allocation)
    @quota_allocation_raw = metadata_hash.fetch(:quota_allocation_raw, 0) # if quota does not exist, set value to 0
    @updated_from_mediaflux_on = metadata_hash[:updated_from_mediaflux_on] if metadata_hash[:updated_from_mediaflux_on]
  end
  # rubocop:enable Metrics/MethodLength
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

  def refresh_from_mediaflux(session_id:)
    metadata_hash = mediaflux_metadata(session_id:)
    initialize_from_hash(metadata_hash)
    update_project
  end

  # @return [String] XML representation of the <meta> element
  def mediaflux_meta_xml(user:)
    doc = ProjectMediaflux.document(project: self, user: user)
    doc.xpath("/response/reply/result/asset/meta").to_s
  end

  def self.default_storage_unit
    "KB"
  end

  def self.default_storage_usage
    "0 #{default_storage_unit}"
  end

  def self.default_storage_capacity
    "0 GB"
  end

  def self.default_quota_allocation
    "0 GB"
  end

  def quota(session_id:)
    quota_req = Mediaflux::ProjectQuotaRequest.new(session_token: session_id, asset_id: mediaflux_id)
    quota_req.quota
  end

  # Fetch the live Mediaflux quota, persist it on metadata_json, and return the quota hash.
  def refresh_storage_capacity_from_mediaflux!(session_id:)
    raise MediafluxError, "Project #{id} has no Mediaflux id; cannot refresh quota" if mediaflux_id.blank?

    quota_info = quota(session_id:)
    human = quota_info[:quota_allocation_human]
    size, unit = parse_human_quota(human)
    apply_approved_quota(size:, unit:)
    update_project
    quota_info
  end

  def as_json(*)
    super.except("project", "mediaflux_metadata")
  end

  private

  def parse_human_quota(human)
    match = human.to_s.strip.match(/\A([\d.]+)\s+([A-Za-z]+)\z/)
    if match.nil?
      raise MediafluxError, "Unable to parse Mediaflux quota allocation #{human.inspect} for project #{id}"
    end

    number = BigDecimal(match[1])
    size = number.frac.zero? ? number.to_i : number.to_f
    [size, match[2]]
  end

  def mediaflux_metadata(session_id:)
    @mediaflux_metadata ||= begin
      metadata_request = Mediaflux::AssetMetadataRequest.new(session_token: session_id, id: mediaflux_id)
      metadata_hash = metadata_request.metadata
      departments = metadata_hash[:departments]
      metadata_hash[:departments] = departments.first.split(", ") if departments.is_a?(Array) && departments.count == 1
      metadata_hash
    end
    @mediaflux_metadata
  end
end
