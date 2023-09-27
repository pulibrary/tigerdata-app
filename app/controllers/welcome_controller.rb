# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    return if current_user.nil?
    @projects = Project.sponsored_projects(@current_user.uid)
  end
end
