# frozen_string_literal: true
class DashboardController < ApplicationController
  def index # rubocop:disable Metrics/AbcSize
    @pending_projects = Project.pending_projects.map { |project| ProjectDashboardPresenter.new(project) }
    @approved_projects = Project.approved_projects.map { |project| ProjectDashboardPresenter.new(project) }
    @eligible_data_user = true if !current_user.eligible_sponsor? && !current_user.eligible_manager?

    @dashboard_projects = Project.users_projects(@current_user).map { |project| ProjectDashboardPresenter.new(project) }

    @my_inventory_requests = current_user.user_requests.where(type: "FileInventoryRequest")
    @dash_session = "project"
    session[:dashtab] ||= @dash_session
    @dash_session = session[:dashtab]
    @session_id = current_user.mediaflux_session
    @emulation_role = session[:emulation_role] || "Not Emulating"
  end

  def emulate
    return if Rails.env.production?

    absolute_user = User.find(current_user.id)
    return unless absolute_user.trainer?

    if params.key?("emulation_menu")
      session[:emulation_role] = params[:emulation_menu]
    end
  end

  def dash_project
    if params.key?("dashtab")
      session[:dashtab] = params[:dashtab]
    end
  end

  def dash_admin
    if params.key?("dashtab")
      session[:dashtab] = params[:dashtab]
    end
  end
end
