# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def index
    if current_user.blank?
      render layout: "welcome"
    else
      redirect_to dashboard_path
    end
  end

  def help; end
end
