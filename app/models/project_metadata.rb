# frozen_string_literal: true
class ProjectMetadata
  attr_accessor :title, :description, :status, :data_sponsor, :data_manager, :departments, :ro_users, :rw_users,
    :created_on, :created_by, :project_id, :project_directory, :project_purpose, :storage_capacity,
    :storage_performance_expectations, :updated_by, :updated_on, :approval_note

  def initialize
    @departments = []
    @ro_users = []
    @rw_users = []
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

  # rubocop:disable Metrics/MethodLength
  def initialize_from_hash(metadata_hash)
    @title = metadata_hash[:title]
    @description = metadata_hash[:description]
    @status = metadata_hash[:status]
    @data_sponsor = metadata_hash[:data_sponsor]
    @data_manager = metadata_hash[:data_manager]
    @departments = metadata_hash[:departments]
    @ro_users = metadata_hash[:ro_users]
    @rw_users = metadata_hash[:rw_users]

    @project_id = metadata_hash[:project_id]
    @project_purpose = metadata_hash[:project_purpose]
    @project_directory = metadata_hash[:project_directory]

    @storage_capacity = metadata_hash[:storage_capacity]
    @storage_performance_expectations = metadata_hash[:storage_performance_expectations]
    @created_on = metadata_hash[:created_on]
    @created_by = metadata_hash[:created_by]
    @updated_by = metadata_hash[:updated_by]
    @updated_on = metadata_hash[:updated_on]
    set_defaults
  end
  # rubocop:enable Metrics/MethodLength

  # Initializes the object with the values in the params (which is an ActionController::Parameters)
  # rubocop:disable Metrics/MethodLength
  def initialize_from_params(params)
    @title = params[:title]
    @description = params[:description]
    @status = params[:status] if params[:status]
    @data_sponsor = params[:data_sponsor]
    @data_manager = params[:data_manager]
    @departments = params[:departments]
    @ro_users = user_list_params(params, read_only_counter(params), "ro_user_")
    @rw_users = user_list_params(params, read_write_counter(params), "rw_user_")

    @project_id = params[:project_id]
    @project_purpose = params[:project_purpose]
    @project_directory = params[:project_directory]

    @storage_capacity = params[:storage_capacity]
    @storage_performance_expectations = params[:storage_performance_expectations]

    @created_by = params[:created_by] if params[:created_by]
    @created_on = params[:created_on] if params[:created_on]
    @updated_by = params[:updated_by] if params[:updated_by]
    @updated_on = params[:updated_on] if params[:updated_on]
    set_defaults
  end
  # rubocop:enable Metrics/MethodLength

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
    set_value(params, "project_directory")

    @ro_users = user_list_params(params, read_only_counter(params), "ro_user_") if params["ro_user_counter"].present?
    @rw_users = user_list_params(params, read_write_counter(params), "rw_user_") if params["rw_user_counter"].present?

    update_storage_capacity(params)
    update_storage_performance_expectations
    update_approval_note(params, current_user)

    # Fields that come from the edit form
    @updated_by = current_user.uid
    @updated_on = Time.current.in_time_zone("America/New_York").iso8601
  end
    # rubocop:enable Metrics/MethodLength

    private

      def read_only_counter(params)
        return if params.nil?
        params[:ro_user_counter].to_i
      end

      def read_write_counter(params)
        return if params.nil?
        params[:rw_user_counter].to_i
      end

      def user_list_params(params, counter, key_prefix)
        return if params.nil?

        users = []
        (1..counter).each do |i|
          key = "#{key_prefix}#{i}"
          users << params[key]
        end
        users.compact.uniq
      end

      # Initializes values that we have defaults for.
      def set_defaults
        if @storage_capacity.nil?
          @storage_capacity = {
            size: { requested: 500, approved: nil },
            unit: { requested: "GB", approved: nil }
          }
        end

        if @storage_performance_expectations.nil?
          @storage_performance_expectations = { requested: "Standard", approved: nil }
        end

        @project_purpose = "Research" if @project_purpose.nil?
      end

      # Sets a value in the object if the value exists in the params
      def set_value(params, key)
        if params[key].present?
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
end
