# frozen_string_literal: true
class EditNewProjectRequestController < ApplicationController
  layout "edit_request"
  before_action :set_breadcrumbs

  before_action :set_new_project_request, only: %i[edit update]
  before_action :check_access

  # GET /edit_new_project_request/1/edit
  def edit
    add_breadcrumb(@new_project_request.project_title, request_path(@new_project_request))
    add_breadcrumb("Edit Submitted Request")
  end

  # PATCH/PUT /edit_new_project_request/1 or /edit_new_project_request/1.json
  def update
    respond_to do |format|
      if @new_project_request.update(request_params) && @new_project_request.valid_to_submit?(allow_empty_parent_folder: true)
        format.html { redirect_to request_url(@new_project_request), notice: I18n.t(:successful_update) }
        format.json { render :show, status: :ok, location: @new_project_request }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @new_project_request.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_new_project_request
      @princeton_departments = Affiliation.all
      @new_project_request = NewProjectRequest.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def request_params
      request_params = params.fetch(:request, {}).permit(:request_title, :project_title, :state, :data_sponsor, :data_manager,
                                        :description, :project_purpose, :parent_folder, :project_folder, :project_id, :quota,
                                        :requested_by, :storage_size, :storage_unit, :number_of_files, :hpc, :smb, :globus,
                                        user_roles: [], departments: [])

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

    def check_access
      return if user_eligible_to_modify_request?

      # request can not be modified by this user, redirect to the request
      flash[:notice] = I18n.t(:no_modify_submitted)
      redirect_to request_path(@new_project_request)
    end

    def user_eligible_to_modify_request?
      # elevated privs for the current user
      if current_user.sysadmin || (current_user.developer && !Rails.env.production?)
        true
      else
        false
      end
    end
end
