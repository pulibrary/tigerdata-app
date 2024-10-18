# frozen_string_literal: true
class Users::MediafluxCallbacksController < ApplicationController
  def passthru
    redirect_to session[:cas_login_url], allow_other_host: true
  end

  def cas
    ticket = params[:ticket]
    msg =  "This is the URL that we could pass throug to mediaflux for them to validate the user who is logged in"
    msg += "It is only valid for 5 seconds  "
    msg += view_context.link_to("ticket validation", session[:cas_validation_url] + ticket)
    flash[:notice] = msg
    redirect_to(root_path)
  end
end
