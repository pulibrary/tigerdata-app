# frozen_string_literal: true
class RequestSubmitController < ApplicationController
  before_action :set_breadcrumbs

  # GET /request_submit
  def index; end

  private

    def set_breadcrumbs
      add_breadcrumb("Dashboard", dashboard_path)
      add_breadcrumb("New Project Request")
    end
end
