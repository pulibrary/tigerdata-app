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
    @project_metadata = @project.metadata

    sponsor_uid = @project_metadata[:data_sponsor]
    @data_sponsor = User.find_by(uid: sponsor_uid)

    manager_uid = @project_metadata[:data_manager]
    @data_manager = User.find_by(uid: manager_uid)

    read_only_uids = @project_metadata.fetch(:data_user_read_only, [])
    unsorted_read_only = read_only_uids.map { |uid| ReadOnlyUser.find_by(uid:) }.reject(&:blank?)
    @data_read_only_users = unsorted_read_only.sort_by { |u| u.given_name || u.uid }

    read_write_uids = @project_metadata.fetch(:data_user_read_write, [])
    unsorted_read_write = read_write_uids.map { |uid| User.find_by(uid:) }.reject(&:blank?)
    @data_read_write_users = unsorted_read_write.sort_by { |u| u.given_name || u.uid }

    unsorted_data_users = @data_read_only_users + @data_read_write_users
    sorted_data_users = unsorted_data_users.sort_by { |u| u.given_name || u.uid }
    @data_users = sorted_data_users.uniq { |u| u.uid }
    user_model_names = @data_users.map(&:data_user_name)
    @data_user_names = user_model_names.join(", ")

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
