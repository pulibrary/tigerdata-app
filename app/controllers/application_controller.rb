# frozen_string_literal: true
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :mediaflux_session
  around_action :mediaflux_session_errors
  around_action :mediaflux_login_errors
  before_action :emulate_user

  helper_method :breadcrumbs

  def new_session_path(_scope)
    new_user_session_path
  end

  def after_sign_in_path_for(_resource)
    mediaflux_passthru_path
    # "/users/#{@user.id}"
  end

  def require_admin_user
    head :forbidden unless current_user&.eligible_sysadmin?
  end

  def breadcrumbs
    @breadcrumbs ||= []
  end

  def add_breadcrumb(name, path = nil)
    breadcrumbs << Breadcrumb.new(name, path)
  end

  private

    def mediaflux_session
      logger.debug "Application Session #{session[:mediaflux_session]} cas: #{session[:active_web_user]}"
      unless ["passthru", "cas"].include?(action_name)
        current_user&.mediaflux_from_session(session)
      end
    end

    def mediaflux_session_errors
      yield
    rescue ActionView::Template::Error, Mediaflux::SessionExpired => e
      raise unless e.is_a?(Mediaflux::SessionExpired) || e.cause.is_a?(Mediaflux::SessionExpired)
      if session[:active_web_user]
        redirect_to mediaflux_passthru_path(path: request.path)
      else
        @retry_count ||= 0
        @retry_count += 1

        current_user.mediaflux_from_session(session)
        if @retry_count < 3 # If the session is expired we should not have to retry more than once, but let's have a little wiggle room
          retry
        else
          raise
        end
      end
    end

    def mediaflux_login_errors
      yield
    rescue Mediaflux::SessionError
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
