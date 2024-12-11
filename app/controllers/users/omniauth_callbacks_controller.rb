# frozen_string_literal: true
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def cas
    access_token = request.env["omniauth.auth"]
    @user = User.from_cas(access_token)

    if @user.nil? && access_token&.provider == "cas"
      redirect_to help_path
      flash.notice = "You can not be signed in at this time."
    elsif @user.nil?
      redirect_to root_path
      flash.alert = "You are not a recognized CAS user."
    else
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
    end
  end
end
