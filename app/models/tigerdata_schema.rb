# frozen_string_literal: true
class TigerdataSchema
  SCHEMA_VERSION = "0.6.1"

  def initialize(session_token:, namespace: "tigerdata", type: "tigerdata:project")
    @session_token = session_token,
    @namespace = namespace
    @type = type
  end

  def fields
    @fields ||= begin
      schema_request = Mediaflux::SchemaFetchRequest.new(session_token: @session_token, namespace: @namespace, type: @type)
      schema_request.resolve
      schema_request.fields
    end
  end

  def required_project_schema_fields
    fields.select { |field| field["min-occurs"] > 0 }
  end
end
