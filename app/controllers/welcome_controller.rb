# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    @projects = MediafluxWrapper.new.projects
  end
end
