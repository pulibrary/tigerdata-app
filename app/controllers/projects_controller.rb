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
    @data_users = @project.metadata[:data_user_read_only].concat(@project.metadata[:data_user_read_write]).sort
    @users = retrieving_name(@data_users)
    @project_metadata = @project.metadata

    sponsor_uid = @project_metadata[:data_sponsor]
    @data_sponsor = User.find_by(uid: sponsor_uid)

    manager_uid = @project_metadata[:data_manager]
    @data_manager = User.find_by(uid: manager_uid)

    read_only_uids = @project_metadata.fetch(:data_user_read_only, [])
    @data_read_only_users = read_only_uids.map { |uid| User.find_by(uid:) }

    read_write_uids = @project_metadata.fetch(:data_user_read_write, [])
    @data_read_write_users = read_write_uids.map { |uid| User.find_by(uid:) }

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

  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    project_metadata = ProjectMetadata.new(project: @project, current_user:)
    @project.metadata = project_metadata.update_metadata(params:)
    if @project.save
      redirect_to @project
    else
      render :edit
    end
  end

  def index
    @projects = Project.all
  end

  def confirmation; end
  private 
    def retrieving_name(data_users) 
      users = []
      data_users.each do |uid|
        user = User.find_by(uid: uid)
        if @project.metadata[:data_user_read_only].include?(uid)
          users << user.display_name_safe + " (read only)"
        else
          users << user.display_name_safe
        end
      end
      users.sort_by! {|user| user.downcase}
    end
end
