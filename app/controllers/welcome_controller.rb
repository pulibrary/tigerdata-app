# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!, except: [:styles_preview]
  skip_before_action :verify_authenticity_token

  def index
    return if current_user.nil?
    @sponsored_projects = Project.sponsored_projects(@current_user.uid)
    @managed_projects = Project.managed_projects(@current_user.uid)
    @data_user_projects = Project.data_user_projects(@current_user.uid)
    @my_projects_count = @sponsored_projects.count + @managed_projects.count + @data_user_projects.count
    @pending_projects = Project.pending_projects
    @approved_projects = Project.approved_projects
    @eligible_data_user = true if !current_user.eligible_sponsor? && !current_user.eligible_manager?

    @my_inventory_requests = current_user.user_requests.where(type: "FileInventoryRequest")
    @dashtab = "classic"
    session[:dashtab] ||= @dashtab
  end

  def emulate
    return if Rails.env.production?
    return if current_user.nil? || current_user.id.nil?

    absolute_user = User.find(current_user.id)
    return unless absolute_user.trainer

    if params.key?("emulation_menu")
      session[:emulation_role] = params[:emulation_menu]
    end
  end

  def tab_project
    return if current_user.nil? || current_user.id.nil?
    if params.key?("dashtab")
      session[:dashtab] = params[:dashtab]
    end
  end

  def tab_activity
    return if current_user.nil? || current_user.id.nil?
    if params.key?("dashtab")
      session[:dashtab] = params[:dashtab]
    end
  end

  def tab_admin
    return if current_user.nil? || current_user.id.nil?
    if params.key?("dashtab")
      session[:dashtab] = params[:dashtab]
    end
  end

  def help
    # Piggybacking on this page to pass custom HTTP headers to Mediaflux
    # in a very controlled scenario.
    root_ns = Rails.configuration.mediaflux["api_root_collection_namespace"]
    parent_collection = Rails.configuration.mediaflux["api_root_collection_name"]
    @test_path = Pathname.new(root_ns).join(parent_collection)
    @test_http_headers = false
    unless current_user.nil?
      @test_http_headers = params["http-headers"] == "true"
      request = if @test_http_headers
                  Mediaflux::AssetExistRequest.new(session_token: current_user.mediaflux_session, path: @test_path, session_user: current_user)
                else
                  Mediaflux::AssetExistRequest.new(session_token: current_user.mediaflux_session, path: @test_path)
                end
      @test_path_exist = request.exist?
    end
  end
end
