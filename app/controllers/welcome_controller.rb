# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    return if current_user.nil?
    @sponsored_projects = Project.sponsored_projects(@current_user.uid)
    @managed_projects = Project.managed_projects(@current_user.uid)
    @data_user_projects = Project.data_user_projects(@current_user.uid)
    @my_projects_count = @sponsored_projects.count + @managed_projects.count + @data_user_projects.count
    @pending_projects = Project.pending_projects
    @approved_projects = Project.approved_projects
    @eligible_data_user = true if !current_user.eligible_sponsor? && !current_user.eligible_manager?

    @my_jobs = current_user.user_jobs
  end

  def emulate
    return if Rails.env.production?
    return unless current_user.trainer

    # TODO: POST TO EMULATE AND PASS THE UPDATED SESSION
    if params.key?("emulation_menu")
      session[:emulation_role] = params[:emulation_menu]
    end
  end

  def help; end
end
