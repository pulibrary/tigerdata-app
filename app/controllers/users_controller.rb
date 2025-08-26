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
    update_user_with_params
    redirect_to user_path(@user)
  rescue => ex
    short_message = "Error saving user #{params[:id]}"
    Rails.logger.error "#{short_message}: #{ex.message}"
    Honeybadger.notify "#{short_message}: #{ex.message}"
    flash[:alert] = short_message
    redirect_to user_path(id: params[:id])
  end

  def lookup
    query = (params["query"] || "").strip.downcase
    matches = []
    if query != ""
      matches = PrincetonUsers.user_list.select { |user| user[:uid].downcase.include?(query) || user[:name].downcase.include?(query) }
    end
    result = {
      suggestions: matches.take(20).map { |match| { "value": match[:name], "data": match[:uid] } }
    }
    render json: result
  end

  private

    def set_breadcrumbs
      add_breadcrumb("Users", users_path)
    end

    def check_user_access
      return if current_user.superuser || current_user.sysadmin || current_user.trainer
      flash[:notice] = "You do not have access to this page (#{current_user.uid})"
      redirect_to dashboard_path
    end

    # rubocop:disable Metrics/AbcSize
    def update_user_with_params
      @user = User.find(params[:id])
      @user.given_name = params["user"]["given_name"]
      @user.family_name = params["user"]["family_name"]
      @user.display_name = params["user"]["display_name"]
      @user.eligible_sponsor = params["user"]["eligible_sponsor"] == "1"
      @user.eligible_manager = params["user"]["eligible_manager"] == "1"
      @user.superuser = params["user"]["superuser"] == "1"
      @user.sysadmin = params["user"]["sysadmin"] == "1"
      @user.trainer = params["user"]["trainer"] == "1"
      @user.save!
    end
  # rubocop:enable Metrics/AbcSize
end
