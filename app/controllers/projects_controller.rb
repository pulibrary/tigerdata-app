# frozen_string_literal: true
class ProjectsController < ApplicationController

  before_action :set_breadcrumbs
  before_action :authenticate_user!

  def new
    add_breadcrumb("New Project Request")
    return build_new_project if current_user.eligible_sponsor?

    redirect_to dashboard_path
  end

  def project_params
    params.dup
  end

  def create
    metadata_params = params.dup
    metadata_params[:status] = Project::PENDING_STATUS
    metadata_params[:created_by] = current_user.uid
    metadata_params[:created_on] = Time.current.in_time_zone("America/New_York").iso8601
    project_metadata = ProjectMetadata.new_from_params(metadata_params)

    build_new_project # calling private method to build a new project and set a class variable @project
    project.create!(initial_metadata: project_metadata, user: current_user)
    if project.metadata_model.project_id != nil
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

  def details
    return if project.blank?

    add_breadcrumb(project.title, project_path)
    add_breadcrumb("Details")

    @departments = project.departments.join(", ")
    @project_metadata = project.metadata_model

    @data_sponsor = User.find_by(uid: @project_metadata.data_sponsor)
    @data_manager = User.find_by(uid: @project_metadata.data_manager)

    read_only_uids = @project_metadata.ro_users
    data_read_only_users = read_only_uids.map { |uid| ReadOnlyUser.find_by(uid:) }.reject(&:blank?)

    read_write_uids = @project_metadata.rw_users
    data_read_write_users = read_write_uids.map { |uid| User.find_by(uid:) }.reject(&:blank?)

    unsorted_data_users = data_read_only_users + data_read_write_users
    sorted_data_users = unsorted_data_users.sort_by { |u| u.family_name || u.uid }
    @data_users = sorted_data_users.uniq { |u| u.uid }
    user_model_names = @data_users.map(&:display_name_safe)
    @data_user_names = user_model_names.join(", ")

    @provenance_events = project.provenance_events.where.not(event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE)

    @project_eligible_to_edit = true if project.status == Project::APPROVED_STATUS && eligible_editor?

    @project_metadata = @project.metadata
    @project_id = @project_metadata[:project_id] || {}
    @storage_capacity = @project_metadata[:storage_capacity]
    @size = @storage_capacity[:size]
    @unit = @storage_capacity[:unit]

    @requested_size = @size[:requested]
    @requested_unit = @unit[:requested]

    @approved_size = @size[:approved]
    @approved_unit = @unit[:approved]

    @storage_expectations = @project_metadata[:storage_performance_expectations]
    @requested_storage_expectations = @storage_expectations[:requested]
    @approved_storage_expectations = @storage_expectations[:approved]

    @project_purpose = @project_metadata[:project_purpose]


    @project_session = "details"


    respond_to do |format|
      format.html do
        @project = ProjectShowPresenter.new(project)
      end
      format.json do
        render json: project.to_json
      end
      format.xml do
        render xml: project.to_xml
      end
    end
  end

  def edit
    add_breadcrumb(project.title, project_path)
    add_breadcrumb("Edit")
    project
    if project.metadata_model.status != Project::APPROVED_STATUS
      flash[:notice] = "Pending projects can not be edited."
      redirect_to project
    elsif project.metadata_model.status == Project::APPROVED_STATUS && !eligible_editor? #check if the current user is a sponsor or a manager
      flash[:notice] = "Only data sponsors and data managers can revise this project."
      redirect_to project
    end
  end

  def update
    @project = Project.find(params[:id])
    #Approve action
    if params.key?("approved")
      @project.metadata_model.update_with_params(params, current_user)
      @project.approve!(current_user:)
    end

    #Edit action
    if params.key?("title")
      @project.metadata_model.status = @project.metadata_model.status || Project::PENDING_STATUS
      @project.metadata_model.update_with_params(params, current_user)
    end

    # @todo ProjectMetadata should be refactored to implement ProjectMetadata.valid?(updated_metadata)
    if project.save and params.key?("approved")
      redirect_to project_approval_received_path(@project)
    elsif project.save and params.key?("title")
      redirect_to project_revision_confirmation_path(@project)
    else
      render :edit
    end
  end

  def index
    if current_user.eligible_sysadmin?
      @projects = Project.all
    else
      flash[:alert] = I18n.t(:access_denied)
      redirect_to dashboard_path
    end
  end

  def confirmation; end
  def revision_confirmation; end

  def show

    return if project.blank?
    add_breadcrumb(project.title, project_path)
    add_breadcrumb("Contents")

    @latest_completed_download = current_user.user_requests.where(project_id: @project.id, state: "completed").order(:completion_time).last
    @storage_usage = project.storage_usage(session_id: current_user.mediaflux_session)
    @storage_capacity = project.storage_capacity(session_id: current_user.mediaflux_session)

    @num_files = project.asset_count(session_id: current_user.mediaflux_session)

    @file_list = project.file_list(session_id: current_user.mediaflux_session, size: 100)
    @files = @file_list[:files]
    @files.sort_by!(&:path)
    @project = ProjectShowPresenter.new(project)

    @project_session = "content"
    respond_to do |format|
      format.html { render }
      format.xml { render xml: @project.to_xml }
    end
  end

  # GET "projects/:id/:id-mf"
  #
  # This action is used to render the mediaflux metadata for a project.
  def show_mediaflux
    project_id = params[:id]
    project = Project.find(project_id)

    respond_to do |format|
      format.xml do
        render xml: project.mediaflux_meta_xml
      end
    end
  end

  def project_job_service
    @project_job_service ||= ProjectJobService.new(project:)
  end

  def list_contents
    return if project.blank?

    project_job_service.list_contents_job(user: current_user)

    json_response = {
      message: "File list for \"#{project.title}\" is being generated in the background. A link to the downloadable file list will be available in the \"Recent Activity\" section of your dashboard when it is available. You may safely navigate away from this page or close this tab."
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
      add_breadcrumb(project.title, project_path)
      add_breadcrumb("Approval Settings", project_approve_path)
      add_breadcrumb("Edit")
      project
      @departments = project.departments.join(", ")
      @project_metadata = project.metadata
      sponsor_uid = @project_metadata[:data_sponsor]
      @data_sponsor = User.find_by(uid: sponsor_uid)
      @provenance_events = project.provenance_events.where.not(event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE)

      @title = @project_metadata["title"]
    else redirect_to dashboard_path
    end
  end

  def create_script
    project_id = params[:id]
    project = Project.find(project_id)
    service = MediafluxScriptFactory.new(project: project)
    respond_to do |format|
      format.json { render json: {script: service.aterm_script} }
    end
  end

  private

    def build_new_project
      @project ||= Project.new
    end

    def project
      @project ||= begin
        project = Project.find(params[:id])
        if project.user_has_access?(user: current_user)
          project
        else
          flash[:alert] = I18n.t(:access_denied)
          redirect_to dashboard_path
          nil
        end
      end
    end

    def eligible_editor?
      return true if current_user.eligible_sponsor? or current_user.eligible_manager?
    end

    def shared_file_location(filename)
      raise "Shared location is not configured" if Rails.configuration.mediaflux["shared_files_location"].blank?
      location = Pathname.new(Rails.configuration.mediaflux["shared_files_location"])
      location.join(filename).to_s
    end

    def set_breadcrumbs
      add_breadcrumb("Dashboard",dashboard_path)
    end
end
