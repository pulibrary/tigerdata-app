# frozen_string_literal: true
class Users::MediafluxCallbacksController < ApplicationController
  def passthru
    session[:original_path] = params["path"]
    redirect_to session[:cas_login_url], allow_other_host: true
  end

  def cas
    ticket = params[:ticket]
    msg =  "This is the URL that we could pass throug to mediaflux for them to validate the user who is logged in"
    msg += "It is only valid once and for 60 seconds ticket: #{ticket} for url: #{session[:cas_validation_url]} "
    msg += view_context.link_to("ticket validation", session[:cas_validation_url] + ticket)
    flash[:notice] = msg
    uri = URI.parse(session[:cas_validation_url])
    token = "#{uri.query}#{ticket}"
    session[:mediaflux_session] = nil
    current_user.mediaflux_from_session(session)
    #  current_user.medaiflux_login(token, session)
    redirect_to(session["original_path"] || dashboard_path)
  end
end
