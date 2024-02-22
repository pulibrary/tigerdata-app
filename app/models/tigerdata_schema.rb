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
    if fields_request.error?
      raise "Could not create or update schema #{fields_request.response_error}"
    end
  end

  def create_aterm_schema_command(line_terminator = nil, _continuation_char = nil)
    namespace_command = "asset.doc.namespace.update :create true :namespace tigerdata :description \"TigerData metadata schema\"\n\n"
    field_command = "asset.doc.type.update :create true :description \"Project metadata\" :type tigerdata:project :definition <#{line_terminator}"
    project_schema_fields.each do |field|
      field_command += " :element -name #{field[:name]} -type #{field[:type]}"
      field_command += " -index #{field[:index]}" if field[:index]
      field_command += " -min-occurs #{field['min-occurs']}"
      field_command += " -max-occurs #{field['max-occurs']}" if field["max-occurs"].present?
      field_command += " -label \"#{field[:label]}\"#{line_terminator}"
    end
    field_command += ">"
    namespace_command + field_command
  end

  def create_aterm_doc_script(filename: Rails.root.join("docs", "schema_script.txt"))
    File.open(filename, "w") do |script|
      script.write("# This file was automatically generated on #{Time.current.in_time_zone('America/New_York').iso8601}\n")
      script.write("# Create the \"tigerdata\" namespace schema and the \"project\" definition inside of it.\n#\n")
      script.write("# To run this script, issue the following command from Aterm\n#\n")
      script.write("# script.execute :in file://full/path/to/tiger-data-app/docs/schema_script.txt\n#\n")
      script.write("# Notice that if you copy and paste the (multi-line) asset.doc.type.update command\n")
      script.write("# into Aterm you'll have to make it single line (i.e. remove the \\)\n")

      script.write(create_aterm_schema_command(" \\\n"))
      script.write("\n")
    end
  end

  # rubocop:disable Metrics/MethodLength
  def project_schema_fields
    # WARNING: Do not use `id` as field name, MediaFlux uses specific rules for an `id` field.
    code = { name: "Code", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The unique identifier for the project" }
    title = { name: "Title", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "A plain-language title for the project" }
    description = { name: "Description", type: "string", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "A brief description of the project" }
    status = { name: "Status", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The current status of the project" }
    data_sponsor = { name: "DataSponsor", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The person who takes primary responsibility for the project" }
    data_manager = { name: "DataManager", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The person who manages the day-to-day activities for the project" }
    data_users = { name: "DataUser", type: "string", index: true, "min-occurs" => 0, label: "A person who has read and write access privileges to the project",
                   attributes: [{ name: "ReadOnly", type: "boolean", index: false, "min-occurs" => 0, label: "Determines whether a given Data User is limited to read-only access to files" }] }
    departments = { name: "Department", type: "string", index: true, "min-occurs" => 1, label: "The primary Princeton University department(s) affiliated with the project" }
    created_on = { name: "CreatedOn", type: "date", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Timestamp project was created" }
    created_by = { name: "CreatedBy", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "User that created the project" }
    updated_on = { name: "UpdatedOn", type: "date", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "Timestamp project was updated" }
    updated_by = { name: "UpdatedBy", type: "string", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "User that updated the project" }
    project_id = { name: "ProjectID", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The pul datacite drafted doi" }
    storage_capacity = { name: "StorageCapacity", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The requested storage capacity (default 500 GB)" }
    storage_performance = { name: "StoragePerformance", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The requested storage performance (default Standard)" }
    project_purpose = { name: "ProjectPurpose", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The project purpose (default Research)" }

    [code, title, description, status, data_sponsor, data_manager, data_users, departments, created_on, created_by, updated_on, updated_by, project_id, storage_capacity,
     storage_performance, project_purpose]
  end
  # rubocop:enable Metrics/MethodLength
end
