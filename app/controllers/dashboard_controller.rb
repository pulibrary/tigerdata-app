# frozen_string_literal: true
class DashboardController < ApplicationController
  layout "welcome"
  around_action :time_dashboard, only: %i[index]

  def index
    @presenter = DashboardPresenter.new(current_user: current_user, display_modal: modal_name)

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

  private

    def modal_name
      if params.key?("modal")
        params[:modal]
      else
        ""
      end
    end

    def time_dashboard
      start_time = Time.current
      yield
    ensure
      end_time = Time.current
      elapsed_time = end_time - start_time
      project_count = nil
      if @dash_session == "project"
        project_count = @presenter&.dashboard_projects&.count
      end
      context = {
        user_id: current_user.id,
        elapsed_time: elapsed_time,
        number_of_projects: project_count
      }

      if elapsed_time > 5.0 && project_count.to_i >= 2
        Honeybadger.notify("Dashboard load time", context: context)
      end
    end
end
