# frozen_string_literal: true
class EditRequestsController < ApplicationController
  layout "edit_request"
  before_action :set_breadcrumbs

  before_action :set_request_model, only: %i[edit update]

  # GET /edit_requests/1/edit
  def edit
    unless current_user.developer || current_user.sysadmin || current_user.trainer
      flash[:notice] = I18n.t(:no_modify_submitted)
      redirect_to request_path(@request_model)
    end
    add_breadcrumb(@request_model.project_title, request_path(@request_model))
    add_breadcrumb("Edit Submitted Request")
  end

  # PATCH/PUT /edit_requests/1 or /edit_requests/1.json
  def update
    if current_user.developer || current_user.sysadmin || current_user.trainer
      respond_to do |format|
        if @request_model.update(request_params) && @request_model.valid_to_submit?
          format.html { redirect_to request_url(@request_model), notice: I18n.t(:successful_update) }
          format.json { render :show, status: :ok, location: @request_model }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @request_model.errors, status: :unprocessable_entity }
        end
      end
    else
      flash[:notice] = I18n.t(:no_modify_submitted)
      redirect_to request_path(@request_model)
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_request_model
      @princeton_departments = Affiliation.all
      @request_model = Request.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def request_params
      request_params = params.fetch(:request, {}).permit(:request_title, :project_title, :state, :data_sponsor, :data_manager,
                                        :description, :parent_folder, :project_folder, :project_id, :quota, :requested_by,
                                        :storage_size, :storage_unit, user_roles: [], departments: [])
      if request_params[:departments].present?
        request_params[:departments] = request_params[:departments].compact_blank.map { |dep_str| JSON.parse(dep_str) }
      end
      if request_params[:user_roles].present?
        request_params[:user_roles] = request_params[:user_roles].compact_blank.map { |role_str| JSON.parse(role_str) }
      end
      move_approved_values(request_params)
    end

    def move_approved_values(request_params)
      if request_params[:quota].present?
        request_params[:approved_quota] = request_params.delete(:quota)
      end
      if request_params[:storage_size].present?
        request_params[:approved_storage_size] = request_params.delete(:storage_size)
      end
      if request_params[:storage_unit].present?
        request_params[:approved_storage_unit] = request_params.delete(:storage_unit)
      end
      request_params
    end

    def set_breadcrumbs
      add_breadcrumb("Dashboard", dashboard_path)
      add_breadcrumb("Requests", requests_path)
    end
end
