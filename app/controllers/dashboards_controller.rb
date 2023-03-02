# frozen_string_literal: true
class DashboardsController < ApplicationController
  def show
    # TODO: Is there a better way to do this efficiently in a single SQL statement?
    allowed_roles = current_user.allowed_roles.map(&:role).map(&:name)
    allowed_role_codes = allowed_roles.map { |role| role.downcase.gsub(/\W/, "-") }

    role_code = params[:role]
    if allowed_role_codes.include?(role_code)
      # TODO: Tighten this and make sure there's no way to load arbitrary files.
      render "/dashboards/#{role_code}"
    else
      render "/access_denied", status: :forbidden
    end
  end
end
