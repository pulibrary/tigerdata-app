# frozen_string_literal: true
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def cas
    access_token = request.env["omniauth.auth"]
    @user = User.from_cas(access_token)

    set_cas_session

    if Flipflop.disable_login? && (@user.present? && !@user.eligible_sysadmin?)
      Rails.logger.warn "User from CAS with netid #{access_token&.uid} tried to log in with login disabled"
      redirect_to root_path
      flash.alert = "TigerData is temporarily unavailable."
    elsif @user.nil? && access_token&.provider == "cas"
      Rails.logger.warn "User from CAS with netid #{access_token&.uid} was not found. Provider: cas"
      redirect_to root_path
      flash.notice = "You can not be signed in at this time."
    elsif @user.nil?
      Rails.logger.warn "User from CAS with netid #{access_token&.uid} was not found. Provider: #{access_token&.provider}"
      redirect_to root_path
      flash.alert = "You are not a recognized CAS user."
    else
      sign_in_and_redirect @user, event: :authentication
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

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
