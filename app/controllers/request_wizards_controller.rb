# frozen_string_literal: true
class RequestWizardsController < ApplicationController
  before_action :set_request_model, only: %i[save]
  before_action :set_or_create_request_model, only: %i[show]

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
      redirect_to dashboard_path
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
      params.fetch(:request, {}).permit(:request_title, :project_title)
    end
end
