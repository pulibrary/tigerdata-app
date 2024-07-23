# frozen_string_literal: true
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  around_action :mediaflux_session
  before_action :emulate_user

  def new_session_path(_scope)
    new_user_session_path
  end

  def require_admin_user
    head :forbidden unless current_user&.eligible_sysadmin?
  end

  private

    def mediaflux_session
      # this requires a connection to mediaflux... for ease of development we do not want to require this
      # current_user&.mediaflux_from_session(session)
      yield
    rescue Mediaflux::SessionExpired
      @retry_count ||= 0
      @retry_count += 1
      current_user.clear_mediaflux_session(session)
      current_user.mediaflux_from_session(session)
      if @retry_count < 3 # If the session is expired we should not have to retry more than once, but let's have a little wiggle room
        retry
      else
        raise
      end
    end

    def emulate_user
      return if Rails.env.production?
      return if current_user.blank? || !current_user.trainer

      if session[:emulation_role]
        if session[:emulation_role] == "Eligible Data Sponsor"
          emulate_sponsor
        elsif session[:emulation_role] == "Eligible Data Manager"
          emulate_manager
        elsif session[:emulation_role] == "System Administrator"
          emulate_sysadmin
        elsif session[:emulation_role] == "Eligible Data User"
          emulate_data_user
        elsif session[:emulation_role] == "Return to Self"
          return_to_self
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
      current_user.trainer = false
      current_user.sysadmin = false
    end

    def return_to_self
      current_user.trainer = true
      current_user.eligible_sponsor = false
      current_user.eligible_manager = false
      current_user.sysadmin = false
    end
end
