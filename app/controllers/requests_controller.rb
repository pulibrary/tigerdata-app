# frozen_string_literal: true
class RequestsController < ApplicationController
  before_action :set_breadcrumbs

  # GET /requests
  def index
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
    if current_user.developer || current_user.sysadmin || current_user.trainer
      @request_model = Request.find(params[:id])
      @request_presenter = RequestPresenter.new(@request_model)
      add_breadcrumb("Requests", requests_path)
      add_breadcrumb(@request_model.project_title, request_path(@request_model))
      render :show
    else
      error_message = "You do not have access to this page."
      flash[:notice] = error_message
      redirect_to dashboard_path
    end
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def approve
    if eligible_to_approve
      @request_model = Request.find(params[:id])
      if @request_model.valid_to_submit?
        project = @request_model.approve(current_user)
        @request_model.destroy!
        stub_message = "The request has been approved and this project was created in the TigerData web portal.  The request has been processed and deleted."
        TigerdataMailer.with(project_id: project.id, approver: current_user).project_creation.deliver_later
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
    if ex.is_a?(Mediaflux::SessionExpired) || ex.cause.is_a?(Mediaflux::SessionExpired)
      raise
    elsif ex.is_a?(ProjectCreate::ProjectCreateError) && ex.message.include?("Session expired for token")
      raise Mediaflux::SessionExpired
    else
      Rails.logger.error "Error approving request #{params[:id]}. Details: #{ex.message}"
      Honeybadger.notify "Error approving request #{params[:id]}. Details: #{ex.message}"
      flash[:notice] = "Error approving request #{params[:id]}"
      redirect_to request_path(@request_model)
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  private

    def set_breadcrumbs
      add_breadcrumb("Dashboard", dashboard_path)
    end

    def eligible_to_approve
      current_user.sysadmin || (current_user.developer && !Rails.env.production?)
    end
end
