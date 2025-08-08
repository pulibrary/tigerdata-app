# frozen_string_literal: true
class RequestsController < ApplicationController
  before_action :set_breadcrumbs

  # GET /requests
  def index
    return head :forbidden unless Flipflop.new_project_request_wizard?
    if current_user.eligible_sysadmin?
      add_breadcrumb("Project Requests - All")
      @draft_requests = Request.where(state: Request::DRAFT).map do |request|
        request.project_title = "no title set" if request.project_title.blank?
        request
      end
      @submitted_requests = Request.where(state: Request::SUBMITTED)
    else
      error_message = "You do not have access to this page."
      flash[:notice] = error_message
      redirect_to dashboard_path
    end
  end

  def show
    if current_user.superuser || current_user.sysadmin || current_user.trainer
      @request_model = Request.find(params[:id])
      add_breadcrumb("Requests", requests_path)
      add_breadcrumb(@request_model.project_title, request_path(@request_model))
      render :show
    else
      error_message = "You do not have access to this page."
      flash[:notice] = error_message
      redirect_to dashboard_path
    end
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def approve
    if current_user.superuser || current_user.sysadmin || current_user.trainer
      @request_model = Request.find(params[:id])
      if @request_model.valid_to_submit?
        project = @request_model.approve(current_user)
        @request_model.destroy
        stub_message = "The request has been approved and this project was created in the TigerData web portal.  The request has been processed and deleted."
        redirect_to project_path(project.id), notice: stub_message
      else
        redirect_to new_project_review_and_submit_path(@request_model)
      end
    else
      error_message = "You do not have access to this page."
      flash[:notice] = error_message
      redirect_to dashboard_path
    end
  rescue StandardError => ex
    Rails.logger.error "Error approving request #{params[:id]}. Details: #{ex.message}"
    Honeybadger.notify "Error approving request #{params[:id]}. Details: #{ex.message}"
    flash[:notice] = "Error approving request #{params[:id]}"
    redirect_to request_path(@request_model)
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  private

    # rubocop:disable Metrics/MethodLength
    def parse_request_metadata(request)
      project_directory = "/tigerdata/#{request[:parent_folder]}/#{request[:project_folder]}"
      departments = request[:departments].map { |d| d["name"] }
      data_users = request[:user_roles].map { |u| u["uid"] }
      {
        title: request[:project_title],
        description: request[:description],
        status: Project::APPROVED_STATUS,
        data_sponsor: request[:data_sponsor],
        data_manager: request[:data_manager],
        departments: departments,
        data_user_read_only: data_users,
        project_directory: project_directory,
        storage_capacity: {
          size: {
            approved: request[:quota].split(" ").first,
            requested: request[:quota].split(" ").first
          },
          unit: {
            approved: request[:storage_unit],
            requested: request[:storage_unit]
          }
        },
        storage_performance_expectations: { requested: "Standard", approved: "Standard" },
        created_by: nil,
        created_on: request[:created_at]
      }
    end
    # rubocop:enable Metrics/MethodLength

    def set_breadcrumbs
      add_breadcrumb("Dashboard", dashboard_path)
    end
end
