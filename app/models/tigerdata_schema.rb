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
      field_command += aterm_element(field:, line_terminator:)
    end
    field_command += ">"
    namespace_command + field_command
  end

  def create_aterm_doc_script(filename: Rails.root.join("docs", "schema_script.txt"))
    File.open(filename, "w") do |script|
      script.write("# This file was automatically generated on #{Time.current.in_time_zone("America/New_York").iso8601}\n")
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
  def self.project_schema_fields
    # WARNING: Do not use `id` as field name, MediaFlux uses specific rules for an `id` field.
    code = { name: "Code", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "Code", description: "The unique identifier for the project" }
    title = { name: "Title", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Title", 
              description: "A plain-language title for the project",
              instructions: "A plain-language title for the project (at the highest level, if sub-projects exist), which will display in metadata records and search results, and which can be edited later (unlike the Project ID)." }
    description = { name: "Description", type: "string", index: false, "min-occurs" => 0, "max-occurs" => 1, 
                    label: "Description", 
                    description: "A brief description of the project",
                    instructions: "A brief description of the project (at the highest level, if sub-projects exist), which serves to summarize the project objectives and (anticipated) data and metadata included in the project."}
    status = { name: "Status", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "Status", description: "The current status of the project" }
    data_sponsor = { name: "DataSponsor", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1,
                    label: "Data Sponsor", 
                    description: "The person who takes primary responsibility for the project",
                    instructions: "The ‘Data Sponsor’ is the person who takes primary responsibility for the project, including oversight of all of the other roles, all of the data contained in the project,"\
                                 " and all of the metadata associated with the data and the project itself."\
                                 " This field is required for all projects in TigerData, and all files in a given project inherit the Data Sponsor value from the project metadata."\
                                 " The person filling the role must be both a registered TigerData user and a current member of the list of eligible Data Sponsors for TigerData." }
    data_manager = { name: "DataManager", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1,
                      label: "Data Manager", 
                      description: "The person who manages the day-to-day activities for the project",
                      instructions: "The ‘Data Manager’ is the person who manages the day-to-day activities for the project, including both data and metadata, but not including role assignments, which is instead determined by the Data Sponsor."\
                                   " (However, the same person may fill both the Data Sponsor and the Data Manager roles on the same project, provided they are eligible for both.) This field is required for all projects in TigerData, and all files in a given project inherit the Data Manager value from the project metadata."\
                                   " The person filling the role must be both a registered TigerData user and current member of the list of eligible Data Managers for TigerData." }
    data_users = { name: "DataUser", type: "string", index: true, "min-occurs" => 0, 
                   label: "Data User(s)", 
                   description: "A person who has read and write access privileges to the project",
                   instructions: "A ‘Data User’ is a person who has access privileges to a given project or file, including data and metadata."\
                                " This field is optional for both projects and files."\
                                " Any number of Data Users may be assigned to a given project or file, with or without a read-only restriction."\
                                " All Data Users must be registered for TigerData prior to assignment.",
                   attributes: [{ name: "ReadOnly", type: "boolean", index: false, "min-occurs" => 0, description: "Determines whether a given Data User is limited to read-only access to files" }] }
    departments = { name: "Department", type: "string", index: true, "min-occurs" => 1, 
                    label: "Affiliated Department(s)",  
                    description: "The primary Princeton University department(s) affiliated with the project",
                    instructions: "The primary Princeton University department(s) affiliated with the project."\
                                  " In cases where the Data Sponsor holds cross-appointments, or where multiple departments are otherwise involved with the project, multiple departments may be recorded." }
    created_on = { name: "CreatedOn", type: "date", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Created On", description: "Timestamp project was created" }
    created_by = { name: "CreatedBy", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Created By", description: "User that created the project" }
    updated_on = { name: "UpdatedOn", type: "date", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "Updated On", description: "Timestamp project was updated" }
    updated_by = { name: "UpdatedBy", type: "string", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "Updated By", description: "User that updated the project" }
    project_id = { name: "ProjectID", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, 
                   label: "Project ID", 
                   description: "The pul datacite drafted doi",
                   instructions: "Records the DOI reserved for the project, from which the automatic code component of the Project ID is determined"}
    storage_capacity = { name: "StorageCapacity", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, 
                         label: "Storage Capacity", 
                         description: "The requested storage capacity (default 500 GB)",
                         instructions: "The anticipated amount of storage needed (in gigabytes or terabytes), given so that the system administrators can prepare the appropriate storage systems for access by the project team" }
    storage_performance = { name: "StoragePerformance", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, 
                            label: "Storage Performance Expectations", 
                            description: "The requested storage performance (default Standard)",
                            instructions: "The expected needs for storage performance, i.e. relative read/write and transfer speeds."\
                                          " The ‘Standard’ default for TigerData is balanced and tuned for moderate usage."\
                                          " Those who expect more intensive usage should select the ‘Premium’ option, while those who expect to simply store their data for long-term, low-usage should select the ‘Eco’ option" }
    project_purpose = { name: "ProjectPurpose", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "Project Purpose", 
                        description: "The project purpose (default Research)",
                        instructions: "The high-level category for the purpose of the project: ‘Research’ (default), ‘Administrative’, or ‘Library Archive’." }

    [code, title, description, status, data_sponsor, data_manager, data_users, departments, created_on, created_by, updated_on, updated_by, project_id, storage_capacity,
     storage_performance, project_purpose]
  end
  # rubocop:enable Metrics/MethodLength
  def project_schema_fields
    self.class.project_schema_fields
  end

  def self.required_project_schema_fields
    project_schema_fields.select { |field| field["min-occurs"] > 0 }
  end

  private

    def aterm_element(field:, line_terminator:)
      field_command = " :element -name #{field[:name]} -type #{field[:type]}"
      field_command += " -index #{field[:index]}" if field[:index]
      field_command += " -min-occurs #{field['min-occurs']}"
      field_command += " -max-occurs #{field['max-occurs']}" if field["max-occurs"].present?
      field_command += " -label \"#{field[:label]}\"" if field[:label].present?
      field_command += line_terminator.to_s
      if field[:description].present? || field[:attributes].present?
        field_command += "   <#{line_terminator}"
        if field[:description].present?
          field_command += "     :description \"#{field[:description]}\"#{line_terminator}"
        end
        if field[:instructions].present?
          field_command += "     :instructions \"#{field[:instructions]}\"#{line_terminator}"
        end
        if field[:attributes].present?
          field[:attributes].each do |attribute|
            field_command += "     :attribute -name #{attribute[:name]} -type #{attribute[:type]} -min-occurs #{attribute['min-occurs']}"
            field_command += "-max-occurs #{attribute['max-occurs']} " if attribute["max-occurs"].present?
            field_command += "#{line_terminator}       < :description \"#{attribute[:description]}\" >"
            field_command += line_terminator.to_s
          end
        end
        field_command += "   >#{line_terminator}"
      end
      field_command  
    end 
end
