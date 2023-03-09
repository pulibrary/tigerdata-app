# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    return if current_user.nil?
    @mf_version = media_flux.version
    @demo_namespace = params[:namespace].nil? ? "/tigerdata/td-demo-001" : params[:namespace]
    start = params[:start].nil? ? 1 : params[:start].to_i
    @result = query_assets(@demo_namespace, start)
  end

  def media_flux
    @media_flux ||= begin
      Rails.logger.info "Connecting to MF"
      host = Rails.configuration.mediaflux["api_host"]
      domain = Rails.configuration.mediaflux["api_domain"]
      user = Rails.configuration.mediaflux["api_user"]
      password = Rails.configuration.mediaflux["api_password"]
      transport = "http"
      MediaFluxClient.new(host, domain, user, password, transport)
    end
  end

  def query_assets(namespace, start)
    # Get the IDs of the assets...
    result = media_flux.query("namespace='#{namespace}'", idx: start)
    # ...fetch the individual metadata for each id
    assets = []
    result[:ids].each do |id|
      metadata = media_flux.get_metadata(id)
      assets << metadata
    end
    { assets: assets, result: result }
  end
end
