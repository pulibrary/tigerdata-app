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
