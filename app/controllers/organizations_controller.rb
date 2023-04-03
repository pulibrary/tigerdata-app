# frozen_string_literal: true
class OrganizationsController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    @organizations = []
    return if current_user.nil?
    @organizations = Organization.list
  end
end
