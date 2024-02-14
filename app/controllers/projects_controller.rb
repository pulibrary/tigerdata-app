# frozen_string_literal: true
class ProjectsController < ApplicationController
  def new
    if current_user.eligible_sponsor?
    new_project
    else redirect_to root_path
    end
  end

  def project_params
    values = params.dup
  end

  def create
    new_project
    project_metadata = ProjectMetadata.new( current_user:, project: new_project)
    new_project_params = params.dup
    metadata_params = new_project_params.merge({
      status: Project::PENDING_STATUS
    })
    project_metadata.create(params: metadata_params)
    if new_project.save
      TigerdataMailer.with(project: @project).project_creation.deliver_later
      redirect_to project_confirmation_path(@project)
    else
      render :new
    end
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

    @submission_events = project.provenance_events.where(event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE)
    @project_status = project.metadata[:status]


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
  end

  def update
    project
    project_metadata = ProjectMetadata.new(project: project, current_user:)
    project.metadata = project_metadata.update_metadata(params:)
    #If an admin approves a project
    if params.key?[:mediaflux_id]
      project.mediaflux_id = params[:mediaflux_id]
    end
    if project.save
      redirect_to project
    else
      render :edit
    end
  end

  def index
    @projects = Project.all
  end

  def confirmation; end

  def contents
    project
    @num_files = project.asset_count(session_id: current_user.mediaflux_session)
    @file_list = project.file_list(session_id: current_user.mediaflux_session, size: 20)
    @file_list[:files].sort_by!(&:path)
  end

  def list_contents
    job = ListProjectContentsJob.perform_later
    user_job = UserJob.create(job_id: job.job_id, project_title: project.title)
    current_user.user_jobs << user_job
    current_user.save!

    json_response = {
      message: "You have a background job running."
    }
    render json: json_response
  end

  def approve
    project
  end

  private

    def new_project
      @project ||= Project.new
    end

    def project
      @project ||= Project.find(params[:id])
    end
end
