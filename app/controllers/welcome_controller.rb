# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!, except: [:styles_preview]
  skip_before_action :verify_authenticity_token

  def index
    if current_user.blank?
      render layout: "welcome"
    else
      redirect_to dashboard_path
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
