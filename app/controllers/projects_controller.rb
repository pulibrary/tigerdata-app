# frozen_string_literal: true
class ProjectsController < ApplicationController

  before_action :set_breadcrumbs
  before_action :authenticate_user!

  def details
    return if project.blank?

    add_breadcrumb(@presenter.title, project_path)
    add_breadcrumb("Details")

    @provenance_events = project.provenance_events.where.not(event_type: ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE)

    @project_eligible_to_edit = true if project.status == Project::APPROVED_STATUS && eligible_editor?

    @project_metadata = @project.metadata
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

    @project_session = "details"

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

    @latest_completed_download = current_user.user_requests.where(project_id: @project.id, state: "completed").order(:completion_time).last
    @storage_usage = project.storage_usage(session_id: current_user.mediaflux_session)
    @storage_capacity = project.storage_capacity(session_id: current_user.mediaflux_session)

    @num_files = project.asset_count(session_id: current_user.mediaflux_session)

    @file_list = project.file_list(session_id: current_user.mediaflux_session, size: 100)
    @files = @file_list[:files]
    @files.sort_by!(&:path)

    @project_session = "content"
    respond_to do |format|
      format.html { render }
      format.xml { render xml: ProjectShowPresenter.new(project, current_user).to_xml
    }
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
    user_request = FileInventoryRequest.where(job_id:job_id).first
    if user_request.nil?
      # TODO: handle error
      redirect_to "/"
    else
      filename = user_request.output_file
      send_data File.read(filename), type: "text/plain", filename: "filelist.csv", disposition: "attachment"
    end
  end

  private

    def project_job_service
      @project_job_service ||= ProjectJobService.new(project:)
    end


    def build_new_project
      @project ||= Project.new
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
        # As of today the search results and the Dashboard show similar information (a list of projects)
        # and it makes sense to use the same presenter. If once we flesh out the search feature the
        # results become too different from each other we can create a specific presenter for the search
        # results.
        @project_presenters = result.value!.map { |project| ProjectDashboardPresenter.new(project, current_user) }
      else
        flash[:notice] = "Error searching projects for #{@title_query}.  Error: #{result.failure}"
        @project_presenters = []
      end
    end
end
