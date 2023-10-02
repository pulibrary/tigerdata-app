# frozen_string_literal: true
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  around_action :mediaflux_session

  def new_session_path(_scope)
    new_user_session_path
  end

  private

    def mediaflux_session
      # this requires a connection to mediaflux
      # current_user&.mediaflux_from_session(session)
      yield
    rescue Mediaflux::Http::SessionExpired
      current_user.clear_mediaflux_session(session)
      current_user.mediaflux_from_session(session)
      retry
    end
end
