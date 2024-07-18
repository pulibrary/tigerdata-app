# frozen_string_literal: true

# Defines the Tigerdata schema in MediaFlux along with the
# document types allowed. At this point we only support "projects"
class TigerdataSchema
  attr_accessor :schema_name, :schema_description

  SCHEMA_VERSION = "0.6.1"

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
    schema_request = Mediaflux::SchemaCreateRequest.new(name: @schema_name,
                                                              description: @schema_description,
                                                              session_token: @session_id)
    schema_request.resolve
  end

  def define_project
    fields_request = Mediaflux::SchemaFieldsCreateRequest.new(
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

  def create_aterm_schema_command(line_terminator = nil)
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
    project_directory = { name: "ProjectDirectory", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "Project Directory", description: "The locally unique name for the project's top-level directory",
                          instructions: "The locally unique name for the project's top-level directory, as shown in a file path. Data Sponsors may suggest a project directory name that is meaningful to them, subject to system administrator approval." 
                        }
    title = { name: "Title", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Title", 
              description: "A plain-language title for the project",
              instructions: "A plain-language title for the project (at the highest level, if sub-projects exist), which will display in metadata records and search results, and which can be edited later (unlike the Project ID)." 
            }
    description = { name: "Description", type: "string", index: false, "min-occurs" => 0, "max-occurs" => 1, 
                    label: "Description", 
                    description: "A brief description of the project",
                    instructions: "A brief description of the project (at the highest level, if sub-projects exist), which serves to summarize the project objectives and (anticipated) data and metadata included in the project."
                  }
    status = { name: "Status", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "Status", description: "The current status of the project",
               instructions: "The current status of the project, as it pertains to the major events tracked by provenance fields (e.g., active, approved, pending, published, or retired)." 
              }
    data_sponsor = { name: "DataSponsor", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1,
                    label: "Data Sponsor", 
                    description: "The person who takes primary responsibility for the project",
                    instructions: "The 'Data Sponsor' is the person who takes primary responsibility for the project, including oversight of all of the other roles, all of the data contained in the project," \
                                 " and all of the metadata associated with the data and the project itself." \
                                 " This field is required for all projects in TigerData, and all files in a given project inherit the Data Sponsor value from the project metadata." \
                                 " The person filling the role must be both a registered TigerData user and a current member of the list of eligible Data Sponsors for TigerData." 
                   }
    data_manager = { name: "DataManager", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1,
                      label: "Data Manager", 
                      description: "The person who manages the day-to-day activities for the project",
                      instructions: "The 'Data Manager' is the person who manages the day-to-day activities for the project, including both data and metadata, but not including role assignments, which is instead determined by the Data Sponsor." \
                                   " (However, the same person may fill both the Data Sponsor and the Data Manager roles on the same project, provided they are eligible for both.) This field is required for all projects in TigerData, and all files in a given project inherit the Data Manager value from the project metadata." \
                                   " The person filling the role must be both a registered TigerData user and current member of the list of eligible Data Managers for TigerData." 
                    }
    data_users = { name: "DataUser", type: "string", index: true, "min-occurs" => 0, 
                   label: "Data User(s)", 
                   description: "A person who has read and write access privileges to the project",
                   instructions: "A 'Data User' is a person who has access privileges to a given project or file, including data and metadata."\
                                " This field is optional for both projects and files."\
                                " Any number of Data Users may be assigned to a given project or file, with or without a read-only restriction."\
                                " All Data Users must be registered for TigerData prior to assignment.",
                   attributes: [{ name: "ReadOnly", type: "boolean", index: false, "min-occurs" => 0, description: "Determines whether a given Data User is limited to read-only access to files" }] }
    departments = { name: "Department", type: "string", index: true, "min-occurs" => 1, 
                    label: "Department(s)",  
                    description: "The primary Princeton University department(s) affiliated with the project",
                    instructions: "The primary Princeton University department(s) affiliated with the project. In cases where the Data Sponsor holds cross-appointments, or where multiple departments are otherwise " \
                                  "involved with the project, multiple departments may be recorded. This field is not meant to capture the departmental affiliations of every person connected to this project, " \
                                  "but rather the departments directly tied to the project itself." 
                  }
    created_on = { name: "CreatedOn", type: "date", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Created On", description: "Timestamp project was created" }
    created_by = { name: "CreatedBy", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Created By", description: "User that created the project" }
    updated_on = { name: "UpdatedOn", type: "date", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "Updated On", description: "Timestamp project was updated" }
    updated_by = { name: "UpdatedBy", type: "string", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "Updated By", description: "User that updated the project" }
    project_id = { name: "ProjectID", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "Project ID", 
                   description: "The universally unique identifier for the project (or in some cases, for the sub-project), automatically generated as a valid DOI compliant with ISO 26324:2012.",
                   instructions: "Records the DOI reserved for the project, from which the automatic code component of the Project ID is determined"
                 }

    requested_attribute = { name: "Requested", type: "string", index: false, "min-occurs" => 0, description: "The requested value provided by the Data Sponsor or Data Manager."}
    approved_attribute = { name: "Approved", type: "string", index: false, "min-occurs" => 0, description: "The value approved and assigned by a system administrator (may not be the same as the requested value)."}
    storage_size = { name: "Size", type: "float", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Size", description: "The numerical value of the quantity",
                     instructions: "The numerical value of the quantity (e.g., count, size, magnitude, etc.)", 
                     attributes: [requested_attribute, approved_attribute]
                    }
    storage_unit = { name: "Unit", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Unit", description: "TThe unit of measure for the quantity",
                     instructions: "TThe unit of measure for the quantity (e.g., MB, GB, TB, etc.",
                     attributes: [requested_attribute, approved_attribute]
                    }
    storage_capacity = { name: "StorageCapacity", type: "document", index: false, "min-occurs" => 1, "max-occurs" => 1, 
                         label: "Storage Capacity", 
                         description: "The requested storage capacity (default 500 GB)",
                         instructions: "The anticipated amount of storage needed (in gigabytes or terabytes), given so that the system administrators can prepare the appropriate storage systems for access by the project team", 
                         sub_elements: [storage_size, storage_unit]
                        }
    storage_performance = { name: "Performance", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, 
                            label: "Storage Performance Expectations", 
                            description: "The requested storage performance (default Standard)",
                            instructions: "The expected needs for storage performance, i.e. relative read/write and transfer speeds."\
                                          " The 'Standard' default for TigerData is balanced and tuned for moderate usage."\
                                          " Those who expect more intensive usage should select the 'Premium' option, while those who expect to simply store their data for long-term, low-usage should select the 'Eco' option",
                            attributes: [requested_attribute, approved_attribute]
                          }
    project_purpose = { name: "ProjectPurpose", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "Project Purpose", 
                        description: "The high-level category for the purpose of the project (research, administrative, or library)",
                        instructions: "The high-level category for the purpose of the project: 'Research' (default), 'Administrative', or 'Library Archive'." 
                      }
    requested_by = { name: "RequestedBy", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Requested By",
                     description: "The person who made the request",
                     instructions: "The person who made the request, given as a locally unique user."
                   }
    requested_date = { name: "RequestDateTime", type: "date", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Request Date-Time", description: "The date and time the request was made",
                       instructions: "The date and time the request was made, following ISO 8601 standards for timestamps." 
                      }
    approved_by = { name: "ApprovedBy", type: "string", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "Approved By",
                       description: "The person who approved the request",
                       instructions: "The person who approved the request, given as a locally unique user."
                     }
    approved_date = { name: "ApprovalDateTime", type: "date", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "Approval Date-Time", description: "The date and time the request was approved",
                         instructions: "The date and time the request was approved, following ISO 8601 standards for timestamps" 
                        }
    denied_by = { name: "DeniedBy", type: "string", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "Denied  By",
                  description: "The person who denied the request",
                  instructions: "The person who denied the request, given as a locally unique user."
                }
    denial_date = { name: "DenialDateTime", type: "date", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "Denial Date-Time", description: "The date and time the request was denied",
                       instructions: "The date and time the request was denied, following ISO 8601 standards for timestamps" 
                      }
    note_by = { name: "NoteBy", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Note By", description: "The person making the note." }
    note_date = { name: "NoteDateTime", type: "date", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Note Date-Time", description: "The date and time the note was made" }
    note_type = { name: "EventType", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Event Type", description: "A general category label for the event note" }
    message = { name: "Message", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Message", description: "The plain-language message contents of the event note." }
    event_note = { name: "EventlNote", type: "document", index: false, "min-occurs" => 0, label: "Event Note(s)", description: "A supplementary record for a provenance event",
                   instructions: "A supplementary record of noteworthy details for a given provenance event (e.g., quota decisions, storage tier assignments, revisions to submitted metadata, explanations of extenuating circumstances, etc.)",
                   sub_elements: [note_by, note_date, note_type, message]
                 }
    submission = { name: "Submission", type: "document", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Submission", description: "A record of a project's initial submission",
                   instructions: "A record of a project's initial submission, including the request to create a new project and the approval or denial by system administrators.",
                   sub_elements: [requested_by, requested_date, approved_by, approved_date, denied_by, denial_date, event_note]
                 }
    revisions = { name: "Revision", type: "document", index: false, "min-occurs" => 0, "max-occurs" => 1, label: "Revision(s)", description: "A record of major revisions to an active project, if applicable",
                   instructions: "A record of major revisions to an active project, if applicable–i.e., those requiring a special request and approval from a system administrator, such as a change in the Data Sponsor or capacity and performance increases.",
                   sub_elements: [requested_by, requested_date, approved_by, approved_date, denied_by, denial_date, event_note]
                 }
    schema_version = { name: "SchemaVersion", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "Schema Version",
                       description: "The version of the TigerData Standard Metadata Schema used",
                       instructions: "The version of the TigerData Standard Metadata Schema used for this project or subproject record. Ordinarily, the version is recorded at the time of the (sub)project creation. Values are expected to follow the numerical semantic versioning convention."
                     }
   [project_directory, title, description, status, data_sponsor, data_manager, data_users, departments, created_on, created_by, updated_on, updated_by, project_id, storage_capacity,
     storage_performance, project_purpose, submission, revisions, schema_version]
  end
  # rubocop:enable Metrics/MethodLength
  def project_schema_fields
    self.class.project_schema_fields
  end

  def self.required_project_schema_fields
    project_schema_fields.select { |field| field["min-occurs"] > 0 }
  end

  private

    def aterm_element(field:, line_terminator:, line_start: "  ")
      new_line_start="#{line_start}  "
      field_command = "#{line_start}:element -name #{field[:name]} -type #{field[:type]}"
      field_command += " -index #{field[:index]}" if field[:index]
      field_command += " -min-occurs #{field['min-occurs']}"
      field_command += " -max-occurs #{field['max-occurs']}" if field["max-occurs"].present?
      field_command += " -label \"#{field[:label]}\"" if field[:label].present?
      field_command += line_terminator.to_s
      if field[:description].present? || field[:attributes].present? || field[:sub_elements]&.count > 0
        field_command += "#{new_line_start}<#{line_terminator}"
        indented_line_start="#{new_line_start}  "
        if field[:description].present?
          field_command += "#{indented_line_start}:description \"#{field[:description]}\"#{line_terminator}"
        end
        if field[:instructions].present?
          field_command += "#{indented_line_start}:instructions \"#{field[:instructions]}\"#{line_terminator}"
        end
        if field[:attributes].present?
          field[:attributes].each do |attribute|
            field_command += "#{indented_line_start}:attribute -name #{attribute[:name]} -type #{attribute[:type]} -min-occurs #{attribute['min-occurs']}"
            field_command += "-max-occurs #{attribute['max-occurs']} " if attribute["max-occurs"].present?
            field_command += "#{line_terminator}#{indented_line_start}  < :description \"#{attribute[:description]}\" >"
            field_command += line_terminator.to_s
          end
        end
        field[:sub_elements]&.each do |sub_field|
          field_command += aterm_element(field: sub_field, line_terminator:, line_start: indented_line_start )
        end
        field_command += "#{new_line_start}>#{line_terminator}"
      end
      field_command  
    end 
end
