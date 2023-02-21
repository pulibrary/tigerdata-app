# frozen_string_literal: true
class WelcomeController < ApplicationController
  def index
    @projects = MediafluxWrapper.new.projects

    flash.alert = "Under Construction!"
    flash.notice = "Welcome to TigerData"
  end
end
