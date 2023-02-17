# frozen_string_literal: true
class WelcomeController < ApplicationController
  def index
    flash.alert = "Under Construction!"
    flash.notice = "Welcome to TigerData"
  end
end
