# frozen_string_literal: true
class RequestsController < ApplicationController
  before_action :set_breadcrumbs

  # GET /requests
  def index
    return head :forbidden unless Flipflop.new_project_request_wizard?
    if current_user.eligible_sysadmin?
      add_breadcrumb("Project Requests - All")
      @requests = Request.all
    else
      error_message = "You do not have access to this page."
      flash[:notice] = error_message
      redirect_to dashboard_path
    end
  end

  def show
    if current_user.superuser || current_user.sysadmin || current_user.trainer
      @request = Request.find(params[:id])
      add_breadcrumb("Requests", requests_path)
      add_breadcrumb(@request.project_title, request_path)
      render :show
    else
      error_message = "You do not have access to this page."
      flash[:notice] = error_message
      redirect_to dashboard_path
    end
  end

  def approve
    if current_user.superuser || current_user.sysadmin || current_user.trainer
      @request = Request.find(params[:id])
      project_directory = "/tigerdata/#{@request[:parent_folder]}/#{@request[:project_folder]}"
      departments = @request[:departments].map { |d| d["name"] }
      data_users = @request[:user_roles].map { |u| u["uid"] }
      metadata_json = {
        title: @request[:project_title],
        description: @request[:description],
        status: Project::APPROVED_STATUS,
        data_sponsor: @request[:data_sponsor],
        data_manager: @request[:data_manager],
        departments: departments,
        data_user_read_only: data_users,
        project_directory: project_directory,
        storage_capacity: {size: { approved: @request[:quota], requested: @request[:quota]}, unit: {approved: @request[:storage_unit], requested: @request[:storage_unit]}},
        storage_performance_expectations: { requested: "Standard", approved: "Standard" },
        created_by: nil,
        created_on: @request[:created_at]
      }

      project = Project.create!({:metadata_json => metadata_json })
      @request.destroy
      stub_message = "Project approved and created in the TigerData web portal; request has been processed and deleted"
      redirect_to dashboard_path, notice: stub_message
    else
      error_message = "You do not have access to this page."
      flash[:notice] = error_message
      redirect_to dashboard_path
    end
  end

  private

    def set_breadcrumbs
      add_breadcrumb("Dashboard", dashboard_path)
    end
end
