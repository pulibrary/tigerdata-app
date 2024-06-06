# frozen_string_literal: true
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  around_action :mediaflux_session
  before_action :emulate_user

  def new_session_path(_scope)
    new_user_session_path
  end

  private

    def mediaflux_session
      # this requires a connection to mediaflux... for ease of development we do not want to require this
      # current_user&.mediaflux_from_session(session)
      yield
    rescue Mediaflux::Http::SessionExpired
      current_user.clear_mediaflux_session(session)
      current_user.mediaflux_from_session(session)
      retry
    end

    def emulate_user
      return if Rails.env.production?
      return if current_user.blank? || !current_user.trainer

      if session[:emulation_role]
        role = session[:emulation_role]
        if role == "sponsor"
          emulate_sponsor
        elsif role == "manager"
          emulate_manager
        elsif role == "sysadmin"
          emulate_sysadmin
        elsif role == "data_user"
          emulate_data_user
        end
      end
    end

    def emulate_sponsor
      current_user.eligible_sponsor = true
      current_user.eligible_manager = false
      current_user.sysadmin = false
    end

    def emulate_manager
      current_user.eligible_manager = true
      current_user.eligible_sponsor = false
      current_user.sysadmin = false
    end

    def emulate_sysadmin
      current_user.sysadmin = true
      current_user.eligible_manager = false
      current_user.eligible_sponsor = false
    end

    def emulate_data_user
      current_user.eligible_sponsor = false
      current_user.eligible_manager = false
      current_user.sysadmin = false
    end
end
