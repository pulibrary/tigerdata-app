# frozen_string_literal: true
class UsersController < ApplicationController
  before_action :set_breadcrumbs
  # GET /requests
  def index
    if current_user.superuser || current_user.sysadmin || current_user.trainer
      @users = User.order("family_name ASC NULLS LAST")
      add_breadcrumb("Current Users")
    else
      error_message = "You do not have access to this page."
      flash[:notice] = error_message
      redirect_to dashboard_path
    end
  end

  private

    def set_breadcrumbs
      add_breadcrumb("Dashboard", dashboard_path)
    end
end
