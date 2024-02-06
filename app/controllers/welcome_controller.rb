# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    return if current_user.nil?
    @sponsored_projects = Project.sponsored_projects(@current_user.uid)
    @managed_projects = Project.managed_projects(@current_user.uid)
    @data_user_projects = Project.data_user_projects(@current_user.uid)
    @my_projects_count = @sponsored_projects.count + @managed_projects.count + @data_user_projects.count

    @my_jobs = current_user.user_jobs
  end

  def help; end
end
