# frozen_string_literal: true
class ProjectsController < ApplicationController
  def show
    @page = (params[:page] || "1").to_i
    @project = Project.get(params[:id])
    @project_files = @project.files_paged(@page)
  end

  def new
    organization = Organization.get(params[:organization_id].to_i, session_id: current_user.mediaflux_session)
    @project = Project.new(-1, "", "", "", organization, session_id: current_user.mediaflux_session)
    render "edit"
  end

  def add_new_files
    id = params[:id].to_i
    project = Project.get(id)
    project.add_new_files(100)
    redirect_to project_path(id: project.id)
  end

  def save
    name = params[:name]
    store_name = params[:store_name]
    organization = Organization.get(params[:organization_id].to_i, session_id: current_user.mediaflux_session)
    id = params[:id].to_i
    project = if id == -1
                # create it
                Project.create!(name, store_name, organization)
              else
                # TODO: in the future save other properties of the project
                Project.get(id)
              end
    redirect_to project_path(id: project.id)
  end
end
