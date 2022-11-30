class SessionsController < ApplicationController
  include Mediaflux

  def new
  end

  def create
    username = params[:session][:username]
    password = params[:session][:password]

    token = fake_login(username, password)
    if token
      redirect_to "/"
    else
      flash[:danger] = "Invalid username / password"
      render 'new'
    end
  end

  def destroy
  end
end
