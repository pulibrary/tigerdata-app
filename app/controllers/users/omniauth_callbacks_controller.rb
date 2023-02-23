# frozen_string_literal: true
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def cas
    @user = User.from_cas(request.env["omniauth.auth"])

    if @user.nil?
      redirect_to root_path
      flash[:notice] = "You are not authorized to view this material"
    else
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
      if is_navigational_format?
        set_flash_message(:notice, :success, kind: "from Princeton Central Authentication "\
                                                  "Service")
      end
    end
  end
end
