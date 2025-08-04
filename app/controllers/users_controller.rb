# frozen_string_literal: true
class UsersController < ApplicationController
  before_action :set_breadcrumbs
  before_action :check_user_access

  def index
    @users = User.order("uid ASC NULLS LAST").page params[:page]
  end

  def show
    add_breadcrumb("User")
    @user = User.find(params[:id])
  end

  def edit
    add_breadcrumb("Edit User")
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    byebug
    # TODO implement update
    redirect_to user_path(@user)
  end

  private

    def set_breadcrumbs
      add_breadcrumb("Users", users_path)
    end

    def check_user_access
      return if current_user.superuser || current_user.sysadmin || current_user.trainer
      flash[:notice] = "You do not have access to this page."
      redirect_to dashboard_path
    end
end
