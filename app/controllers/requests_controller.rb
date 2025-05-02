# frozen_string_literal: true
class RequestsController < ApplicationController
  before_action :set_breadcrumbs

  # GET /requests
  def index
    return head :forbidden unless Flipflop.new_project_request_wizard?
    add_breadcrumb("New Project Request")
  end

  private

    def set_breadcrumbs
      add_breadcrumb("Dashboard", dashboard_path)
    end
end
