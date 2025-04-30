class RequestsController < ApplicationController
  before_action :set_breadcrumbs

  # GET /requests
  def index
    add_breadcrumb("New Project Request")
  end

  private

    def set_breadcrumbs
      add_breadcrumb("Dashboard",dashboard_path)
    end
end
