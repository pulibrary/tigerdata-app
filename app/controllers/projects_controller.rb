# frozen_string_literal: true
class ProjectsController < ApplicationController
  def new
    @project = Project.new
    @project.created_by_user = current_user
  end

  def create
    @project = Project.new
    @project.metadata = form_metadata
    @project.created_by_user = current_user
    @project.save!
    TigerdataMailer.with(project: @project).project_creation.deliver_later
    redirect_to @project
  end

  def show
    @project = Project.find(params[:id])
    debugger
  end

  def approve
    @project = Project.find(params[:id])
    xml_namespace = params[:xml_namespace]
    @project.approve!(session_id: current_user.mediaflux_session, created_by: current_user.uid, xml_namespace: xml_namespace)
    redirect_to @project
  end

  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    @project.metadata = form_metadata
    @project.save!

    if @project.in_mediaflux?
      # Ideally this should happen inside the model, but since the code requires the Mediaflux session
      # we'll keep it here for now.
      @project.update_mediaflux(session_id: current_user.mediaflux_session, updated_by: current_user.uid)
    end

    redirect_to @project
  end

  def index
    @projects = Project.all
  end

  private

    def read_only_counter
      params[:ro_user_counter].to_i
    end

    def read_write_counter
      params[:rw_user_counter].to_i
    end

    def user_list_params(counter, key_prefix)
      users = []
      (1..counter).each do |i|
        key = "#{key_prefix}#{i}"
        users << params[key]
      end
      users.compact.uniq
    end

    def form_metadata
      ro_users = user_list_params(read_only_counter, "ro_user_")
      rw_users = user_list_params(read_write_counter, "rw_user_")
      {
        data_sponsor: params[:data_sponsor],
        data_manager: params[:data_manager],
        departments: params[:departments],
        directory: params[:directory],
        title: params[:title],
        description: params[:description],
        data_user_read_only: ro_users,
        data_user_read_write: rw_users
      }
    end
end
