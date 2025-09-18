# frozen_string_literal: true
class RequestWizardsController < ApplicationController
  layout "wizard"
  before_action :set_breadcrumbs

  before_action :set_request_model, only: %i[save]
  before_action :exit_without_saving, only: %i[save]
  before_action :set_or_init_request_model, only: %i[show]

  before_action :check_flipper

  attr_reader :request_model

  # GET /request_wizards/1
  def show
    if current_user.developer || current_user.sysadmin || current_user.trainer
      # create a request in the first step
      render_current
    else
      error_message = "You do not have access to this page."
      flash[:notice] = error_message
      redirect_to dashboard_path
    end
  end

  # PUT /request_wizards/1/save
  def save
    # save and render dashboard
    save_request
    case params[:commit]
    when "Back"
      render_back
    when "Next"
      render_next
    else
      if params[:commit].start_with?("http")
        # Go directly to the step the user clicked on
        redirect_to params[:commit]
      else
        redirect_to request_path(@request_model)
      end
    end
  end

  private

    def exit_without_saving
      if params[:commit] == "Exit without Saving"
        if @request_model.nil?
          redirect_to dashboard_path
        else
          redirect_to request_path(@request_model)
        end
      end
    end

    def render_current
      raise "Must be implemented"
    end

    def render_next
      raise "Must be implemented"
    end

    def render_back
      raise "Must be implemented"
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_request_model
      # do nothing if we are bailing out without creating a request2
      return if params[:request_id] == "0" && params[:commit] == "Exit without Saving"

      @request_model = if params[:request_id] == "0"
                         # on the first page with a brand new request that has not been created
                         req = Request.create
                         update_sidebar_url(req)
                         req
                       else
                         # on a page when the request has already been created
                         Request.find(params[:request_id])
                       end
    end

    def update_sidebar_url(request_model)
      return unless params[:commit].start_with?("http")

      # take of the zero in the url and replace it with the real request id
      params[:commit] = "#{params[:commit][0..-2]}#{request_model.id}"
    end

    # set if id is present or initialize a blank request if not
    def set_or_init_request_model
      @princeton_departments = Affiliation.all
      @request_model = if params[:request_id].blank?
                         Request.new(id: 0)
                       else
                         Request.find(params[:request_id])
                       end
    end

    def save_request
      request_model.update(request_params)
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
        request_params[:user_roles] = request_params[:user_roles].compact_blank.map do |role_str|
          json = JSON.parse(role_str)
          json["read_only"] = params[:request]["read_only_#{json['uid']}"] == "true"
          json
        end
      end
      request_params[:requested_by] ||= current_user.uid
      request_params
    end

    def check_flipper
      return head :forbidden unless Flipflop.new_project_request_wizard?
    end

    def set_breadcrumbs
      add_breadcrumb("Dashboard", dashboard_path)
    end
end
