# frozen_string_literal: true
class ProjectsController < ApplicationController
  def new
    @project = Project.new
  end

  def create
    @project = Project.new
    project_metadata = ProjectMetadata.new( current_user:, project: @project)
    project_metadata.create(params:)
    if @project.save
      TigerdataMailer.with(project: @project).project_creation.deliver_later
      redirect_to project_confirmation_path(@project)
    else
      render :new
    end
  end

  def show
    @project = Project.find(params[:id])
    respond_to do |format|
      format.html
      format.json do
        render json: @project.to_json
      end
      format.xml do
        render xml: @project.to_xml
      end
    end
  end

  # def approve
  #   @project = Project.find(params[:id])
  #   xml_namespace = params[:xml_namespace]
  #   @project.approve!(session_id: current_user.mediaflux_session, xml_namespace: xml_namespace)
  #   redirect_to @project
  # end

  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    project_metadata = ProjectMetadata.new(project: @project, current_user:)
    @project.metadata = project_metadata.update_metadata(params:)
    if @project.save
      if @project.in_mediaflux?
        # Ideally this should happen inside the model, but since the code requires the Mediaflux session
        # we'll keep it here for now.
        @project.update_mediaflux(session_id: current_user.mediaflux_session)
      end

      redirect_to @project
    else
      render :edit
    end
  end

  def index
    @projects = Project.all
  end

  def confirmation; end
end
