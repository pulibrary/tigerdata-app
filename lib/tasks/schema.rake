# frozen_string_literal: true
# :nocov:
namespace :schema do
  # Define the TigerData schema
  desc "define the tigerdata schema in the current mediaflux instance"
  task create: :environment do
    # TODO: Make sure we login with a user that has access to
    # asset.doc.type.update and asset.doc.type.update
    logon_request = Mediaflux::Http::LogonRequest.new
    logon_request.resolve
    schema = TigerdataSchema.new(session_id: logon_request.session_token)
    schema.create
  end

  desc "create the script to define the tigerdata schema in mediaflux"
  task create_script: :environment do
    tigerdata_schema = TigerdataSchema.new(session_id: nil)
    tigerdata_schema.create_aterm_doc_script
  end

  task asset_exist: :environment do
    user = User.where(uid:"hc8719").first
    path = "/td-test-001/root1"
    exist_req = Mediaflux::Http::AssetExistRequest.new(session_token: user.mediaflux_session, path:)
    puts "#{path} exists? #{exist_req.exist?}"
  end

  task root_create: :environment do
    user = User.where(uid:"hc8719").first
    namespace = "/td-test-001"
    name = "root2"
    create_req = Mediaflux::Http::CollectionAssetCreateRoot.new(session_token: user.mediaflux_session, namespace:, name:)
    puts "root created with id #{create_req.id}"
  end


end
# :nocov:
