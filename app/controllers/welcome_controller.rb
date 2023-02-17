# frozen_string_literal: true
class WelcomeController < ApplicationController
  def index
    @projects = MediafluxWrapper.new.projects
  end
end
