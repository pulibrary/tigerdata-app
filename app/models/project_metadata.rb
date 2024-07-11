# frozen_string_literal: true
class ProjectMetadata
  attr_accessor :title, :description, :status, :data_sponsor, :data_manager, :departments, :ro_users, :rw_users,
    :created_on, :created_by, :project_id, :project_directory, :project_purpose, :storage_capacity,
    :storage_performance_expectations, :updated_by, :updated_on, :approval_note

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

  # TODO: we might NOT need two separate methods
  # (i.e initialize_from_hash and initialize_from_params)
  #
  # rubocop:disable Metrics/AbcSize
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
    # TODO: make sure handle this?
    # @project_directory = ?

    @storage_capacity = metadata_hash[:storage_capacity]
    @storage_performance_expectations = metadata_hash[:storage_performance_expectations]
    @created_on = metadata_hash[:created_on]
    @created_by = metadata_hash[:created_by]
    @updated_by = metadata_hash[:updated_by]
    @updated_on = metadata_hash[:updated_on]
    set_defaults
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def initialize_from_params(params)
    @title = params[:title]
    @description = params[:description]
    @status = params[:status] if params[:status]
    @data_sponsor = params[:data_sponsor]
    @data_manager = params[:data_manager]
    @departments = params[:departments]
    @ro_users = user_list_params(params, read_only_counter(params), "ro_user_")
    @rw_users = user_list_params(params, read_write_counter(params), "rw_user_")

    # self.project_id = project.metadata[:project_id] || "" # allow validation to pass until doi can be generated
    # self.project_purpose = project.metadata[:project_purpose]
    # self.project_directory = params[:project_directory]

    @storage_capacity = params[:storage_capacity]
    @storage_performance_expectations = params[:storage_performance_expectations]

    @created_by = params[:created_by] if params[:created_by]
    @created_on = params[:created_on] if params[:created_on]
    @updated_by = params[:updated_by] if params[:updated_by]
    @updated_on = params[:updated_on] if params[:updated_on]
    set_defaults
  end

  def update_with_params(params, current_user)
    self.title = params["title"] unless params["title"].nil?
    self.description = params["description"] unless params["description"].nil?
    self.status = params["status"] unless params["status"].nil?
    self.data_sponsor = params["data_sponsor"] unless params["data_sponsor"].nil?
    self.data_manager = params["data_manager"] unless params["data_manager"].nil?
    self.departments = params["departments"] unless params["departments"].nil?
    self.ro_users = user_list_params(params, read_only_counter(params), "ro_user_") if params["ro_user_counter"].present?
    self.rw_users = user_list_params(params, read_write_counter(params), "rw_user_") if params["rw_user_counter"].present?

    # project_id is not defined by the user (it's the DOI)
    # project_purpose is not defined by the user
    unless params["project_directory"].nil?
      self.project_directory = params["project_directory"]
      # TODO: "#{params[:project_directory_prefix]}/#{params[:project_directory]}"
    end

    unless params["storage_capacity"].nil?
      self.storage_capacity = {
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

    # we don't allow the user to specify an approve value so we use the requested
    self.storage_performance_expectations = {
      "requested" => storage_performance_expectations[:requested],
      "approved" => storage_performance_expectations[:requested]
    }

    unless params["approval_note"].nil?
      self.approval_note = {
        note_by: current_user.uid,
        note_date_time: Time.current.in_time_zone("America/New_York").iso8601,
        event_type: project_params[:event_note],
        message: project_params[:event_note_message]
      }
    end

    # Fields that come from the edit form
    self.updated_by = current_user.uid
    self.updated_on = Time.current.in_time_zone("America/New_York").iso8601
  end

  def draft_doi
    self.project_id = "TBD"
    # TODO: re-implement this method
    return
    puldatacite = PULDatacite.new
    project.metadata_json["project_id"] = puldatacite.draft_doi
    project.save!
    data_sponsor = User.find_by(uid: project.metadata[:data_sponsor])
    project.provenance_events.create(event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE, event_person: current_user.uid, event_details: "Requested by #{data_sponsor.display_name_safe}")
    project.provenance_events.create(event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE, event_person: current_user.uid, event_details: "The Status of this project has been set to pending")
  end

  def activate_project(collection_id:, current_user:)
    response = Mediaflux::Http::AssetMetadataRequest.new(session_token: current_user.mediaflux_session, id: collection_id)
    metadata = response.metadata
    return unless metadata[:collection] == true # If the collection id exists

    # check if the project doi in rails matches the project doi in mediaflux
    return unless metadata[:project_id] == project.metadata_json["project_id"]

    # activate a project by setting the status to 'active'
    project.metadata_json["status"] = Project::ACTIVE_STATUS

    # also read in the actual project directory
    project.metadata_json["project_directory"] = metadata[:project_directory]

    project.save!

    # create two provenance events, one for approving the project and another for changing the status of the project
    project.provenance_events.create(event_type: ProvenanceEvent::ACTIVE_EVENT_TYPE, event_person: current_user.uid, event_details: "Activated by Tigerdata Staff")
    project.provenance_events.create(event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE, event_person: current_user.uid, event_details: "The Status of this project has been set to active")
  end

  def generate_approval_events(note)
    # create two provenance events, one for approving the project and another for changing the status of the project
    project.provenance_events.create(event_type: ProvenanceEvent::APPROVAL_EVENT_TYPE, event_person: current_user.uid, event_details: "Approved by #{current_user.display_name_safe}",
                                     event_note: note)
    project.provenance_events.create(event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE, event_person: current_user.uid, event_details: "The Status of this project has been set to approved")
  end

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

      # I copied these values from project.yml
      #
      # TODO: review if we want to keep project.yml or hard code them here.
      # The yml approach made sense when we were using a (dynamic) hash, but
      # less so now that we have an explicit class for the values.
      def set_defaults
        if storage_capacity.nil?
          self.storage_capacity = {
            size: { requested: 500, approved: nil },
            unit: { requested: "GB", approved: nil }
          }
        end

        if storage_performance_expectations.nil?
          self.storage_performance_expectations = { requested: "Standard", approved: nil }
        end

        if project_purpose.nil?
          self.project_purpose = "Research"
        end
      end
end
