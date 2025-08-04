# frozen_string_literal: true
class TigerdataSchema
  SCHEMA_VERSION = "0.6.1"

  def initialize(namespace: "tigerdata", type: "tigerdata:project")
    @namespace = namespace
    @type = type
  end

  def fields
    @fields ||= begin
      logon_request = Mediaflux::LogonRequest.new
      schema_request = Mediaflux::SchemaFetchRequest.new(session_token: logon_request.session_token, namespace: @namespace, type: @type)
      schema_request.resolve
      schema_request.fields
    end
  end

  def required_project_schema_fields
    fields.select { |field| field["min-occurs"] > 0 }
  end
end
