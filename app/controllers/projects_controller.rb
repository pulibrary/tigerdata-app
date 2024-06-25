# frozen_string_literal: true
class ProjectsController < ApplicationController
  def new
    return build_new_project if current_user.eligible_sponsor?

    redirect_to root_path
  end

  def project_params
    params.dup
  end

  def create
    project_metadata = ProjectMetadata.new( current_user:, project: build_new_project)
    new_project_params = project_params
    metadata_params = new_project_params.merge({
      status: Project::PENDING_STATUS
    })
    project_metadata.create(params: metadata_params)
    if project.save
      begin
        mailer = TigerdataMailer.with(project_id: project.id)
        message_delivery = mailer.project_creation
        message_delivery.deliver_later

        redirect_to project_confirmation_path(project)
      rescue StandardError => mailer_error
        raise(TigerData::MailerError, mailer_error)
      end
    else
      render :new
    end
  rescue TigerData::MailerError => mailer_error
    logger_message = "Error encountered creating the project #{project.id} as user #{current_user.email}"
    Rails.logger.error(logger_message)
    honeybadger_context = {
      current_user_email: current_user.email,
      project_id: project.id,
      project_metadata: project.metadata
    }
    Honeybadger.notify(mailer_error, context: honeybadger_context)

    error_message = "We are sorry, while the project was successfully created, an error was encountered which prevents the delivery of an e-mail message confirming this. Please know that this error has been logged, and shall be reviewed by members of RDSS."
    flash[:notice] = error_message

    render :new
  rescue StandardError => error
    logger_message = if project.persisted?
                      "Error encountered creating the project #{project.id} as user #{current_user.email}"
                     else
                      "Error encountered creating the project #{metadata_params[:title]} as user #{current_user.email}"
                     end
    Rails.logger.error(logger_message)
    honeybadger_context = {
      current_user_email: current_user.email,
      project_id: project.id,
      project_metadata: project.metadata
    }
    Honeybadger.notify(error, context: honeybadger_context)

    error_message = "We are sorry, the project was not successfully created, and an error was encountered which prevents the delivery of an e-mail message confirming this. Please know that this error has been logged, and shall be reviewed by members of RDSS promptly."

    flash[:notice] = error_message
    render :new
  end

  def show
    project
    @departments = project.departments.join(", ")
    @project_metadata = project.metadata

    sponsor_uid = @project_metadata[:data_sponsor]
    @data_sponsor = User.find_by(uid: sponsor_uid)

    manager_uid = @project_metadata[:data_manager]
    @data_manager = User.find_by(uid: manager_uid)

    read_only_uids = @project_metadata.fetch(:data_user_read_only, [])
    data_read_only_users = read_only_uids.map { |uid| ReadOnlyUser.find_by(uid:) }.reject(&:blank?)

    read_write_uids = @project_metadata.fetch(:data_user_read_write, [])
    data_read_write_users = read_write_uids.map { |uid| User.find_by(uid:) }.reject(&:blank?)

    unsorted_data_users = data_read_only_users + data_read_write_users
    sorted_data_users = unsorted_data_users.sort_by { |u| u.family_name || u.uid }
    @data_users = sorted_data_users.uniq { |u| u.uid }
    user_model_names = @data_users.map(&:display_name_safe)
    @data_user_names = user_model_names.join(", ")

    @provenance_events = project.provenance_events.where.not(event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE)

    @project_eligible_to_edit = true if project.status == Project::APPROVED_STATUS && eligible_editor?

    respond_to do |format|
      format.html
      format.json do
        render json: project.to_json
      end
      format.xml do
        render xml: project.to_xml
      end
    end
  end

  def edit
    project
    if project.metadata[:status] != Project::APPROVED_STATUS
      flash[:notice] = "Pending projects can not be edited."
      redirect_to project
    elsif project.metadata[:status] == Project::APPROVED_STATUS && !eligible_editor? #check if the current user is a sponsor of manager
      flash[:notice] = "Only data sponsors and data managers can revise this project."
      redirect_to project
    end
  end

  def update
    project
    #Approve action
    if params.key?("mediaflux_id")
      project_metadata = ProjectMetadata.new(project: project, current_user:)
      project_params = params.dup
      metadata_params = project_params.merge({
        project_directory: project_params["project_directory"],
        storage_capacity: {"size"=>{"approved"=>project_params["storage_capacity"].to_i, 
                            "requested"=>project.metadata[:storage_capacity][:size][:requested]}, 
                            "unit"=>{"approved"=>project_params["storage_unit"], 
                                     "requested"=>project.metadata[:storage_capacity][:unit][:requested]}},
        # no current input to set approved storage performance, so just copy requested
        storage_performance_expectations: {"requested"=>project.metadata[:storage_performance_expectations][:requested],
                                           "approved"=>project.metadata[:storage_performance_expectations][:requested]},
        approval_note: {
          note_by: current_user.uid,
          note_date_time: Time.current.in_time_zone("America/New_York").iso8601,
          event_type: project_params[:event_note],
          message: project_params[:event_note_message]
        }
      })
      project_metadata.approve_project(params: metadata_params)
    end

    #Edit action
    if params.key?("title")
      project_metadata = ProjectMetadata.new(project: project, current_user:)
      project_params = params.dup
      metadata_params = project_params.merge({
        status: project.metadata[:status]
      })
      project.metadata = project_metadata.update_metadata(params: metadata_params)
    end

    # @todo ProjectMetadata should be refactored to implement ProjectMetadata.valid?(updated_metadata)
    if project.save and params.key?("mediaflux_id")
      redirect_to project_approval_received_path(@project)
    elsif project.save and params.key?("title")
      redirect_to project_revision_confirmation_path(@project)
    else
      render :edit
    end
  end

  def index
    @projects = Project.all
  end

  def confirmation; end
  def revision_confirmation; end

  def contents
    project

    @storage_usage = project.storage_usage(session_id: current_user.mediaflux_session)
    @storage_capacity = project.storage_capacity(session_id: current_user.mediaflux_session)

    @num_files = project.asset_count(session_id: current_user.mediaflux_session)

    @file_list = project.file_list(session_id: current_user.mediaflux_session, size: 100)
    @files = @file_list[:files]
    @files.sort_by!(&:path)
  end

  def project_job_service
    @project_job_service ||= ProjectJobService.new(project:)
  end

  def list_contents
    project_job_service.list_contents_job(user: current_user)

    json_response = {
      message: "File list for \"#{project.title}\" is being generated in the background."
    }
    render json: json_response
  rescue => ex
    message = "Error producing document list (project id: #{project&.id}): #{ex.message}"
    Rails.logger.error(message)
    Honeybadger.notify(message)
    render json: { message: "Document list could not be generated." }
  end

  def file_list_download
    job_id = params[:job_id]
    user_request = FileInventoryRequest.where(job_id:job_id).first
    if user_request.nil?
      # TODO: handle error
      redirect_to "/"
    else
      filename = user_request.output_file
      send_data File.read(filename), type: "text/plain", filename: "filelist.csv", disposition: "attachment"
    end
  end

  def approve
    if current_user.eligible_sysadmin?
      project
      @departments = project.departments.join(", ")
      @project_metadata = project.metadata
      sponsor_uid = @project_metadata[:data_sponsor]
      @data_sponsor = User.find_by(uid: sponsor_uid)
      @provenance_events = project.provenance_events.where.not(event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE)

      @project_metadata = project.metadata
      @title = @project_metadata["title"]
    else redirect_to root_path
    end
  end

  private

    def build_new_project
      @project ||= Project.new
    end

    def project
      @project ||= Project.find(params[:id])
    end

    def eligible_editor?
      return true if current_user.eligible_sponsor? or current_user.eligible_manager?
    end

    def shared_file_location(filename)
      raise "Shared location is not configured" if Rails.configuration.mediaflux["shared_files_location"].blank?
      location = Pathname.new(Rails.configuration.mediaflux["shared_files_location"])
      location.join(filename).to_s
    end
end
