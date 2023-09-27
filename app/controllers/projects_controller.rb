# frozen_string_literal: true
class ProjectsController < ApplicationController
  def new
    @project = Project.new
  end

  def create
    @project = Project.new
    @project.metadata = form_metadata
    @project.save!
    redirect_to @project
  end

  def show
    @project = Project.find(params[:id])
    if params[:create_mf] == "true"
      asset_id = ProjectMediaflux.create!(project: @project, session_id: current_user.mediaflux_session, created_by: current_user.uid)
      if asset_id > 0
        @project.mediaflux_id = asset_id
        @project.save!
      end
    end
  end

  def approve
    @project = Project.find(params[:id])
    @project.approve!(session_id: current_user.mediaflux_session, created_by: current_user.uid)
    redirect_to @project
  end

  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    @project.metadata = form_metadata
    @project.save!
    redirect_to @project
  end

  def save
    @project = Project.find(params[:id])
    @project.metadata = form_metadata
    @project.save!
    redirect_to @project
  end

  def index
    @projects = Project.all
  end

  private

    def form_metadata
      {
        data_sponsor: params[:data_sponsor],
        data_manager: params[:data_manager],
        departments: params[:departments],
        directory: params[:directory],
        title: params[:title],
        description: params[:description]
      }
    end
end
