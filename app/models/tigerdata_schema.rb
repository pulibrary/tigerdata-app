# frozen_string_literal: true

# Defines the Tigerdata schema in MediaFlux along with the
# document types allowed. At this point we only support "projects"
class TigerdataSchema
  attr_accessor :schema_name, :schema_description

  def initialize(schema_name: nil, schema_description: nil, session_id:)
    @schema_name = schema_name || "tigerdata"
    @schema_description = schema_description || "TigerData Metadata"
    @session_id = session_id
  end

  def create
    define_schema_namespace
    define_project
  end

  def define_schema_namespace
    schema_request = Mediaflux::Http::SchemaCreateRequest.new(name: @schema_name,
                                                              description: @schema_description,
                                                              session_token: @session_id)
    schema_request.resolve
  end

  def define_project
    fields_request = Mediaflux::Http::SchemaFieldsCreateRequest.new(
      schema_name: @schema_name,
      document: "project",
      description: "Project Metadata",
      fields: project_schema_fields,
      session_token: @session_id
    )
    fields_request.resolve
  end

  def project_schema_fields
    # WARNING: Do not use `id` as field name, MediaFlux uses specific rules for an `id` field.
    code = { name: "code", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The unique identifier for the project" }
    title = { name: "title", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "A plain-language title for the project" }
    description = { name: "description", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "A brief description of the project" }
    data_sponsor = { name: "data_sponsor", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The person who takes primary responsibility for the project" }
    data_manager = { name: "data_manager", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The person who manages the day-to-day activities for the project" }
    data_users_rw = { name: "data_users_rw", type: "string", index: true, "min-occurs" => 0, label: "A person who has read and write access privileges to the project" }
    data_users_ro = { name: "data_users_ro", type: "string", index: true, "min-occurs" => 0, label: "A person who has read-only access privileges to the project" }
    departments = { name: "departments", type: "string", index: true, "min-occurs" => 1, label: "The primary Princeton University department(s) affiliated with the project" }
    created_on = { name: "created_on", type: "date", index: false, "min-occurs" => 1, label: "Timestamp project was created" }
    created_by = { name: "created_by", type: "string", index: false, "min-occurs" => 1, label: "User that created the project" }
    updated_on = { name: "updated_on", type: "date", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "Timestamp project was updated" }
    updated_by = { name: "updated_by", type: "string", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "User that updated the project" }

    [code, title, description, data_sponsor, data_manager, data_users_rw, data_users_ro, departments, created_on, created_by, updated_on, updated_by]
  end
end