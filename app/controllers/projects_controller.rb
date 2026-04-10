# frozen_string_literal: true
class ProjectsController < ApplicationController

  before_action :set_breadcrumbs
  before_action :authenticate_user!

  def details
    return if project.blank?

    add_breadcrumb(@presenter.title, project_path)
    add_breadcrumb("Details")

    project_metadata = @project.metadata
    storage_capacity = project_metadata[:storage_capacity]
    size = storage_capacity[:size]
    unit = storage_capacity[:unit]

    @requested_size = size[:requested]
    @requested_unit = unit[:requested]

    @approved_size = size[:approved]
    @approved_unit = unit[:approved]

    @project_session = "details"
    @show_quota_breakdown = params["quota"] == "true"

    respond_to do |format|
      format.html do
        render
      end
      format.json do
        render json: project.to_json
      end
      format.xml do
        render xml: @presenter.to_xml
      end
    end
  end

  def index
    if current_user.eligible_sysadmin?
      search_projects
    else
      flash[:alert] = I18n.t(:access_denied)
      redirect_to dashboard_path
    end
  end

  def show
    return if project.blank?

    add_breadcrumb(@presenter.title, project_path)
    add_breadcrumb("Contents")

    @latest_completed_download = current_user.inventory_requests.where(project_id: @project.id, state: "completed").order(:completion_time).last
    @storage_usage = project.storage_usage(session_id: current_user.mediaflux_session)
    @storage_capacity = project.storage_capacity(session_id: current_user.mediaflux_session)

    @num_files = project.asset_count(session_id: current_user.mediaflux_session)

    @project_file_display_limit = Rails.configuration.project_file_display_limit
    if Flipflop.new_file_details?
      @directory_list = project.directory_listing(session_id: current_user.mediaflux_session, size: @project_file_display_limit)
      @files = @directory_list[:files]
    else
      @file_list = project.file_list(session_id: current_user.mediaflux_session, size: @project_file_display_limit)
      @files = @file_list[:files]
      @files.sort_by!(&:path)
    end

    @project_session = "content"
    respond_to do |format|
      format.html { render }
      format.xml { render xml: ProjectShowPresenter.new(project, current_user).to_xml
    }
    end
  end

  # GET "projects/:id/file-explorer"
  # Used via an AJAX call to retrieve the list of files for a given path within a project
  def file_explorer
    project # force the presenter to be set

    if params["pathId"].to_i == 0
      path = @presenter.project_directory
      path_id = project.mediaflux_id
    else
      path = params["path"]
      path_id = params["pathId"].to_i
    end

    iterator_id = if params["iteratorId"].to_i == 0
      # setup a new iterator
      project.file_explorer_setup(session_id: current_user.mediaflux_session, path_id: path_id)
    else
      # use the existing iterator
      params["iteratorId"].to_i
    end

    mediaflux_data = project.file_explorer_iterate(session_id: current_user.mediaflux_session, iterator_id: iterator_id)
    if mediaflux_data[:error]
      render json: {}, status: 500
    else
      data = {
        fileListUrl: project_file_explorer_url,
        currentPath: path,
        currentPathId: path_id,
        iteratorId: iterator_id,
        files: mediaflux_data[:files],
        complete: mediaflux_data[:complete]
      }
      render json: data
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
        render xml: project.mediaflux_meta_xml(user: current_user)
      end
    end
  rescue => ex
    Rails.logger.error "Error getting MediaFlux XML for project #{project_id}, user #{current_user.uid}: #{ex.message}"
    flash[:alert] = "Error fetching Mediaflux XML for this project"
    redirect_to project_path(project_id)
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
    file_inventory_request = FileInventoryRequest.where(job_id:job_id).first
    if file_inventory_request.nil?
      # TODO: handle error
      redirect_to "/"
    else
      filename = file_inventory_request.output_file
      send_data File.read(filename), type: "text/plain", filename: "filelist.csv", disposition: "attachment"
    end
  end

  def send_globus_access_request
    project_id = params[:project_id].to_i
    TigerdataMailer.with(project_id: project_id, submitter: current_user).globus_access_request.deliver_later
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def send_storage_increase_request
    project_id = params[:project_id].to_i
    requested_capacity = params[:requested_capacity]
    justification = params[:justification]
    growth_expectation = params[:growth_expectation]
    date_needed = params[:date_needed]
    project = Project.find(project_id)
    quota_breakdown = ProjectShowPresenter.new(project, current_user).quota_breakdown
    TigerdataMailer.with(
      project_id: project_id,
      submitter: current_user,
      requested_capacity: requested_capacity,
      justification: justification,
      growth_expectation: growth_expectation,
      date_needed: date_needed,
      quota_breakdown: quota_breakdown
      ).storage_increase_request.deliver_later
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

    def project_job_service
      @project_job_service ||= ProjectJobService.new(project:)
    end

    def project
      @project ||= begin
        project = Project.find(params[:id])
        @presenter = ProjectShowPresenter.new(project, current_user)
        if project&.mediaflux_id != nil && @presenter.user_has_access?(user: current_user)
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

    def set_breadcrumbs
      add_breadcrumb("Dashboard",dashboard_path)
    end

    def search_projects
      @title_query = if params[:title_query].present?
        params[:title_query]
      else
        "*" # default to all projects
      end
      result =  ProjectSearch.new.call(search_string: @title_query, requestor: current_user)
      if result.success?
        flash[:notice] = "Successful search in Mediaflux for #{@title_query}"
        @project_presenters = result.value!
      else
        flash[:notice] = "Error searching projects for #{@title_query}.  Error: #{result.failure}"
        @project_presenters = []
      end
    end
end
