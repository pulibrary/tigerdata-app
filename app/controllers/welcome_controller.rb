# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    return if current_user.nil?

    start = params[:start].nil? ? 1 : params[:start].to_i
    @mf_version = media_flux.version
    @demo_namespace = params[:namespace].nil? ? "/tigerdata/td-demo-001" : params[:namespace]
    @demo_collection = nil
    @result = nil
    if params[:collection]
      @demo_collection = params[:collection]
      @demo_namespace = "Collection #{@demo_collection}"
      @result = query_collection(@demo_collection, start)
    else
      @result = query_assets(@demo_namespace, start)
    end
  end

  def create_collection_asset
    namespace = params[:namespace]
    if namespace.present?
      name = "collection-#{filename_now}"
      id = media_flux.create_collection_asset(namespace, name)
      Rails.logger.info "Created collection asset id #{id} in #{namespace}, name #{name}"
    else
      Rails.logger.info "No collection asset created"
    end
    redirect_to root_url + "?namespace=#{namespace}"
  end

  def create_asset
    collection_id = params[:collection]
    if collection_id.present?
      name = "file-#{filename_now}"
      id = media_flux.create_in_collection(collection_id, name)
      Rails.logger.info "Created asset id #{id} in #{collection_id}, name #{name}"
    else
      Rails.logger.info "No asset created"
    end
    redirect_to root_url + "?collection=#{collection_id}"
  end

  def set_note
    id = params[:id]
    note = media_flux.get_metadata(id)[:mf_note] || ""
    note += "Added a note at #{Time.now.getlocal} #{Time.now.zone}\r\n"
    media_flux.set_note(id, note)
    redirect_to root_url

    unless Rails.env.development?
      @mf_version = media_flux.version
      @demo_namespace = params[:namespace].nil? ? "/tigerdata/td-demo-001" : params[:namespace]
      start = params[:start].nil? ? 1 : params[:start].to_i
      @result = query_assets(@demo_namespace, start)
    end
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

  def query_collection(collection_id, start)
    # Get the IDs of the assets...
    result = media_flux.query_collection(collection_id, idx: start)
    # ...fetch the individual metadata for each id
    assets = []
    result[:ids].each do |id|
      metadata = media_flux.get_metadata(id)
      assets << metadata
    end
    { assets: assets, result: result }
  end

  def filename_now
    "#{Time.now.in_time_zone.yday}-#{Time.now.seconds_since_midnight.to_i}"
  end
end
