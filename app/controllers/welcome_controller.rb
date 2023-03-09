# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    host = Rails.configuration.mediaflux["api_host"]
    domain = Rails.configuration.mediaflux["api_domain"]
    user = Rails.configuration.mediaflux["api_user"]
    password = Rails.configuration.mediaflux["api_password"]
    transport = "http"

    mf = MediaFluxClient.new(host, domain, user, password, transport)
    @demo_namespace = "/tigerdata/td-demo-001"
    @mf_version = mf.version
    @assets = query_assets(mf)
  end


  def query_assets(mf)
    assets = []
    asset_ids = mf.query("namespace='#{@demo_namespace}'")
    asset_ids.each do |id|
      metadata = mf.get_metadata(id)
      assets << metadata
    end
    assets
  end
end
