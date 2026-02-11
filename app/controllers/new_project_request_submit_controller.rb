# frozen_string_literal: true
class NewProjectRequestSubmitController < ApplicationController
  before_action :set_breadcrumbs

  # GET /new_project_request_submit
  def index; end

  private

    def set_breadcrumbs
      add_breadcrumb("Dashboard", dashboard_path)
      add_breadcrumb("New Project Request")
    end
end
