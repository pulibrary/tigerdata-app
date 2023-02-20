class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def cas
      # You need to implement the method below in your model (e.g. app/models/user.rb)
      @user = User.from_cas(request.env["omniauth.auth"])
 
      unless @user.nil?
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: 'from Princeton Central Authentication '\
                                                  'Service') if is_navigational_format?
      else
        redirect_to root_path
        flash[:notice] = 'You are not authorized to view this material'
      end
    end
end