# frozen_string_literal: true
class Users::MediafluxCallbacksController < ApplicationController
  def passthru
    session[:original_path] = params["path"]
    redirect_to session[:cas_login_url], allow_other_host: true
  end

  def cas
    ticket = params[:ticket]
    uri = URI.parse(session[:cas_validation_url])
    token = "#{uri.query}#{ticket}"
    current_user.mediaflux_login(token, session)
    redirect_to(session["original_path"] || dashboard_path)
  end
end
