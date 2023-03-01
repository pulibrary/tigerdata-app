# frozen_string_literal: true
class DashboardsController < ApplicationController
  def show
    user_config = YAML.load_file("seeds/users.yaml")[current_user.uid]
    unless user_config
      render "/access_denied", status: :forbidden
      return
    end

    @allowed_roles = user_config["allowed_roles"]
    @role = params[:role]
    if @allowed_roles.include?(@role)
      render "/dashboards/#{@role}"
    else
      render "/access_denied", status: :forbidden
    end
  end
end
