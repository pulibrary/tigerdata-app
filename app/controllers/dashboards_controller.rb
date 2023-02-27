# frozen_string_literal: true
class DashboardsController < ApplicationController
  def show
    uid = current_user.uid
    allowed_roles = YAML.load_file("users.yaml")[uid]["roles"]
    @role = params[:role]
    unless allowed_roles.include?(@role)
      render "/access_denied", status: :forbidden
    end
  end
end
