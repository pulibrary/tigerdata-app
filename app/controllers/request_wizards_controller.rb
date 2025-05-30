# frozen_string_literal: true
class RequestWizardsController < ApplicationController
  layout "wizard"
  before_action :set_breadcrumbs

  before_action :set_request_model, only: %i[save]
  before_action :set_or_create_request_model, only: %i[show]

  before_action :check_flipper

  attr_reader :request_model

  # GET /request_wizards/1
  def show
    # create a request in the first step
    render_current
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
      redirect_to "#{requests_path}/#{@request_model.id}"
    end
  end

  private

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
      @request_model = Request.find(params[:request_id])
    end

    # set if id is present or create request if not
    def set_or_create_request_model
      @princeton_departments = Affiliation.all.map { |dep| "(#{dep.code}) #{dep.name}" }
      @princeton_users = PrincetonUsers.user_list
      if params[:request_id].blank?
        @request_model = Request.create
      else
        set_request_model
      end
    end

    def save_request
      request_model.update(request_params)
    end

    # Only allow a list of trusted parameters through.
    def request_params
      request_params = params.fetch(:request, {}).permit(:request_title, :project_title, :state, :data_sponsor, :data_manager, :departments,
                                        :description, :parent_folder, :project_folder, :project_id, :quota, :requested_by, user_roles: [])
      if request_params[:departments].present?
        request_params[:departments] = clean_department_list request_params[:departments]
      end
      if request_params[:user_roles].present?
        request_params[:user_roles] = request_params[:user_roles].compact_blank.map { |role_str| JSON.parse(role_str) }
      end
      request_params
    end

    def clean_department_list(department_list)
      department_list = department_list.gsub(",,", ",")
      if department_list.start_with?(",")
        department_list = department_list[1..]
      end
      department_list
    end

    def check_flipper
      return head :forbidden unless Flipflop.new_project_request_wizard?
    end

    def set_breadcrumbs
      add_breadcrumb("Dashboard", dashboard_path)
    end
end
