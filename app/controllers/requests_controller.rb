# frozen_string_literal: true
class RequestsController < ApplicationController
  before_action :set_breadcrumbs

  # GET /requests
  def index
    return head :forbidden unless Flipflop.new_project_request_wizard?
    if current_user.eligible_sysadmin?
      add_breadcrumb("New Project Request")
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
      stub_message = "Edit the 'approve' method in app/controllers/requests_controller.rb to do something when this button is clicked"
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
