# frozen_string_literal: true
class RequestsController < ApplicationController
  before_action :set_breadcrumbs

  # GET /requests
  def index
    return head :forbidden unless Flipflop.new_project_request_wizard?
    add_breadcrumb("New Project Request")
    @requests = Request.all
  end

  def show
    @request = Request.find(params[:id])
    add_breadcrumb("Requests", requests_path)
    add_breadcrumb(@request.project_title, request_path)
    render :show
  end

  def approve
    stub_message = "Edit the 'approve' method in app/controllers/requests_controller.rb to do something when this button is clicked"
    redirect_to dashboard_path, notice: stub_message
  end

  private

    def set_breadcrumbs
      add_breadcrumb("Dashboard", dashboard_path)
    end
end
