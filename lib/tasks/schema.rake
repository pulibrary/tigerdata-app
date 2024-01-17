# frozen_string_literal: true
# :nocov:
namespace :schema do
  # Define the TigerData schema
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
end
# :nocov:
