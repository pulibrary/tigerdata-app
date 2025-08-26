# frozen_string_literal: true
class DashboardController < ApplicationController
  layout "welcome"

  def index
    @presenter = DashboardPresenter.new(current_user: current_user)

    session[:dashtab] ||= "project" # default the session tab to projects
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
