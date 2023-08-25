# frozen_string_literal: true
class OrganizationsController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    @organizations = []
    return if current_user.nil?
    @organizations = Organization.list(session_id: current_user.mediaflux_session)
  end

  def show
    @organization = Organization.get(params[:id], session_id: current_user.mediaflux_session)
  end
end
