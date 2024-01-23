# frozen_string_literal: true
class ProjectMetadata
  attr_reader :project, :current_user, :params
  def initialize(current_user:, project:)
    @project = project
    @current_user = current_user
  end

  def update_metadata(params:)
    @params = params
    form_metadata
  end

  def create( params:)
    project.metadata = update_metadata(params:)
    if project.valid? && project.metadata["project_id"].blank?
      puldatacite = PULDatacite.new
      project.metadata_json["project_id"] = puldatacite.draft_doi
      project.save!
      data_sponsor = User.find_by(uid: project.metadata[:data_sponsor])
      project.provenance_events.create(event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE, event_person: current_user.uid, event_details: "Requested by #{data_sponsor.display_name_safe}")
      project.provenance_events.create(event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE, event_person: current_user.uid, event_details: "The Status of this project has been set to pending")
    end
    project.metadata["project_id"]
  end

    private

      def read_only_counter
        params[:ro_user_counter].to_i
      end

      def read_write_counter
        params[:rw_user_counter].to_i
      end

      def user_list_params(counter, key_prefix)
        users = []
        (1..counter).each do |i|
          key = "#{key_prefix}#{i}"
          users << params[key]
        end
        users.compact.uniq
      end

      def project_timestamps
        timestamps = {}
        if project.metadata[:created_by].nil?
          timestamps[:created_by] = current_user.uid
          timestamps[:created_on] = DateTime.now.strftime("%d-%b-%Y %H:%M:%S")

        else
          timestamps[:created_by] = project.metadata[:created_by]
          timestamps[:created_on] = project.metadata[:created_on]
          timestamps[:updated_by] = current_user.uid
          timestamps[:updated_on] = DateTime.now.strftime("%d-%b-%Y %H:%M:%S")
        end
        timestamps
      end

      def form_metadata
        ro_users = user_list_params(read_only_counter, "ro_user_")
        rw_users = user_list_params(read_write_counter, "rw_user_")
        data = {
          data_sponsor: params[:data_sponsor],
          data_manager: params[:data_manager],
          departments: params[:departments],
          directory: params[:directory],
          title: params[:title],
          description: params[:description],
          status: params[:status],
          data_user_read_only: ro_users,
          data_user_read_write: rw_users,
          project_id: project.metadata[:project_id],
          storage_capacity_requested: project.metadata[:storage_capacity_requested] || Rails.configuration.project_defaults[:storage_capacity_requested],
          storage_performance_expectations_requested: project.metadata[:storage_performance_expectations_requested] || Rails.configuration.project_defaults[:storage_performance_expectations_requested],
          project_purpose: project.metadata[:project_purpose] || Rails.configuration.project_defaults[:project_purpose]
        }
        timestamps = project_timestamps
        data.merge(timestamps)
      end
end
