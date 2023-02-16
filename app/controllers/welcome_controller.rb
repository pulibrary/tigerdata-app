# frozen_string_literal: true
class WelcomeController < ApplicationController
  def index
    @projects = ApiMiddleware.new.projects
  end
end
