# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
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
    {
      requested: false,
      approved: false
    }
  end

  # @return [Hash] The default Samba/SMB request Hash entries
  def self.default_smb_request
    {
      requested: false,
      approved: false
    }
  end

  # @return [Boolean] The default value for whether a project is provisional
  def self.default_provisionality
    false
  end


  attr_accessor(
    :title, :description, :status, :data_sponsor, :data_manager, :departments, :data_user_read_only, :data_user_read_write,
    :created_on, :created_by, :project_id, :project_directory, :project_purpose, :storage_capacity, :storage_performance_expectations,
    :updated_by, :updated_on, :approval_note, :schema_version, :submission,
    # NOTE: The following attributes are required by the XML schema
    :hpc,
    :data_use_agreement,
    :project_visibility,
    :resource_type,
    :project_directory_protocol,
    :globus_request,
    :smb_request,
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

  def self.new_from_params(metadata_params)
    pm = ProjectMetadata.new
    pm.initialize_from_params(metadata_params)
    pm
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
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
    @project_directory = metadata_hash[:project_directory]

    @storage_capacity = metadata_hash[:storage_capacity]
    @storage_performance_expectations = metadata_hash[:storage_performance_expectations]

    @created_by = metadata_hash[:created_by] if metadata_hash[:created_by]
    @created_on = metadata_hash[:created_on] if metadata_hash[:created_on]
    @updated_by = metadata_hash[:updated_by] if metadata_hash[:updated_by]
    @updated_on = metadata_hash[:updated_on] if metadata_hash[:updated_on]

    # NOTE: The following attributes are required by the 0.8 XML schema
    @hpc = metadata_hash[:hpc] || self.class.default_hpc

    @data_use_agreement = metadata_hash[:data_use_agreement] || self.class.default_data_use_agreement

    @project_visibility = metadata_hash[:project_visibility] || self.class.default_project_visibility
    @resource_type = metadata_hash[:resource_type] || self.class.default_resource_type

    @globus_request = metadata_hash[:globus_request] || self.class.default_globus_request
    @smb_request = metadata_hash[:smb_request] || self.class.default_smb_request

    @provisional = metadata_hash[:provisional] || self.class.default_provisionality

    set_defaults
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  # Initializes the object with the values in the params (which is an ActionController::Parameters)
  def initialize_from_params(params)
    @data_user_read_only = ro_users_from_params(params)
    @data_user_read_write = rw_users_from_params(params)
    initialize_from_hash(params)
  end

  # Updates the object with the values in the params (which is an ActionController::Parameters)
  # Notice how we only update values that come in the params and don't change the values that
  # don't come as part of the params
  # rubocop:disable Metrics/MethodLength
  def update_with_params(params, current_user)
    set_value(params, "title")
    set_value(params, "description")
    set_value(params, "status")
    set_value(params, "data_sponsor")
    set_value(params, "data_manager")
    set_value(params, "departments")
    set_value(params, "project_id")
    set_value(params, "project_purpose")
    calculate_project_directory(params)

    if params["data_user_counter"].present?
      @data_user_read_only = ro_users_from_params(params)
      @data_user_read_write = rw_users_from_params(params)
    end

    update_storage_capacity(params)
    update_storage_performance_expectations
    update_approval_note(params, current_user)
    @submission = params[:submission] if params[:submission]

    # Fields that come from the edit form
    @updated_by = current_user.uid
    @updated_on = Time.current.in_time_zone("America/New_York").iso8601
  end
  # rubocop:enable Metrics/MethodLength

  # Alias for `data_user_read_only`
  def ro_users
    @data_user_read_only
  end

  # Alias for `data_user_read_write`
  def rw_users
    @data_user_read_write
  end

    private

      def data_users_from_params(params, access)
        return [] if params.nil?
        users = []
        counter = params[:data_user_counter].to_i
        (1..counter).each do |i|
          key = "data_user_#{i}"
          access_key = key + "_read_access"
          if params[access_key] == access
            users << params[key]
          end
        end
        users.compact.uniq
      end

      def ro_users_from_params(params)
        data_users_from_params(params, "read-only")
      end

      def rw_users_from_params(params)
        data_users_from_params(params, "read-write")
      end

      # Initializes values that we have defaults for.
      def set_defaults
        if @storage_capacity.nil?
          @storage_capacity = Rails.configuration.project_defaults[:storage_capacity]
        end

        if @storage_performance_expectations.nil?
          @storage_performance_expectations = Rails.configuration.project_defaults[:storage_performance_expectations]
        end

        if @project_purpose.nil?
          @project_purpose = Rails.configuration.project_defaults[:project_purpose]
        end

        @submission = { "requested_by" => @created_by, "request_date_time" => @created_on } if @submission.nil?
        @schema_version = TigerdataSchema::SCHEMA_VERSION
      end

      # Sets a value in the object if the value exists in the params
      def set_value(params, key)
        if params.include?(key)
          send("#{key}=", params[key])
        end
      end

      def update_storage_capacity(params)
        if params["storage_capacity"].present?
          @storage_capacity = {
            "size" => {
              "approved" => params["storage_capacity"].to_i,
              "requested" => storage_capacity[:size][:requested]
            },
            "unit" => {
              "approved" => params["storage_unit"],
              "requested" => storage_capacity[:unit][:requested]
            }
          }
        end
      end

      def update_storage_performance_expectations
        # we don't allow the user to specify an approve value so we use the requested
        @storage_performance_expectations = {
          "requested" => storage_performance_expectations[:requested],
          "approved" => storage_performance_expectations[:requested]
        }
      end

      def update_approval_note(params, current_user)
        if params[:event_note_message].present?
          @approval_note = {
            note_by: current_user.uid,
            note_date_time: Time.current.in_time_zone("America/New_York").iso8601,
            event_type: params[:event_note],
            message: params[:event_note_message]
          }
        end
      end

      def calculate_project_directory(params)
        if params["project_directory_prefix"].present?
          current_directory = params["project_directory"]
          @project_directory = Pathname.new(params["project_directory_prefix"]).join(current_directory)
        else
          set_value(params, "project_directory")
        end
      end
end
# rubocop:enable Metrics/ClassLength
