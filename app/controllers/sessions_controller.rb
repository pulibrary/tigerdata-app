class SessionsController < ApplicationController
  include Mediaflux

  def new
  end

  def create
    username = params[:session][:username]
    password = params[:session][:password]

    token = fake_login(username, password)

    render 'new'
  end

  def destroy
  end
end
