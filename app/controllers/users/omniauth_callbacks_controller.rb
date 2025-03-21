# frozen_string_literal: true
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def cas
    access_token = request.env["omniauth.auth"]
    @user = User.from_cas(access_token)

    set_cas_session

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

  private

    def set_cas_session
      strategy = request.env["omniauth.strategy"]
      if strategy.present?
        service_url = strategy.append_params(mediaflux_extra_url, { url: request.referer })
        session[:cas_login_url] = strategy.login_url(service_url)
        session[:cas_validation_url] = strategy.service_validate_url(service_url, "")
      end
    end
end
