# frozen_string_literal: true
namespace :schema do
  # Define the TigerData schema and the Project specification inside of it
  task create: :environment do
    # TODO: Make sure we login with a user that has access to
    # asset.doc.type.update and asset.doc.type.update
    logon_request = Mediaflux::Http::LogonRequest.new
    logon_request.resolve
    logon_request.session_token
    Project.create_schema(session_id: logon_request.session_token)
  end
end
