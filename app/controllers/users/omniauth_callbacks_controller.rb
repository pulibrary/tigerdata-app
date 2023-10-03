# frozen_string_literal: true
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def cas
    @user = User.from_cas(request.env["omniauth.auth"])

    if @user.nil?
      redirect_to root_path
      flash.alert = "You are not a recognized CAS user."
    elsif @user.has_role? :project_sponsor
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
      flash.notice = "Welcome, #{@user.given_name}"
    else
      redirect_to help_path
      flash.notice = "You can not be signed in at this time."
    end
  end
end
