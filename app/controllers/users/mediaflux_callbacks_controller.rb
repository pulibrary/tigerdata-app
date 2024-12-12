# frozen_string_literal: true
class Users::MediafluxCallbacksController < ApplicationController
  def passthru
    redirect_to session[:cas_login_url], allow_other_host: true
  end

  def cas
    ticket = params[:ticket]
    uri = URI.parse(session[:cas_validation_url])
    token = "#{uri.query}#{ticket}"
    current_user.medaiflux_login(token, session)
    redirect_to(root_path)
  end
end
