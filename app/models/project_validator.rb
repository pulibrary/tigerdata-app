class ProjectValidator < ActiveModel::Validator
    def validate(project, user)
        @schema = TigerdataSchema.new(session_token: user.session_token, namespace: "tigerdata", type: "tigerdata:project")

        # we need this because this method references the metadata_json which is not updated until the project is saved
        project.metadata = project.metadata_model

        # Required fields, always validate
        validate_role(project:, netid: project.metadata_model.data_manager, role: "Data Manager")
        validate_role(project:, netid: project.metadata_model.data_sponsor, role: "Data Sponsor")

        # Validate if present
        project.metadata_model.data_user_read_only&.each { |read_only| validate_role(project:, netid: read_only, role: "Data User Read Only")}
        project.metadata_model.data_user_read_write&.each { |read_write| validate_role(project:, netid: read_write, role: "Data User Read Write")}

        # validate all required fields
        required_metadata_field_errors = []
        required_metadata = required_attributes(project:)
        if required_metadata.values.include?(nil)
            required_keys.each do |attr|
                value = required_metadata[attr]
                required_metadata_field_errors << "Missing metadata value for #{attr}" if value.nil? && project.metadata_json.include?(attr)
            end
        end
        if required_metadata_field_errors.count > 0
            project.errors.add :base, "Invalid Project Metadata it does not match the schema #{TigerdataSchema::SCHEMA_VERSION}\n #{required_metadata_field_errors.join(", ")}"
        end
    end

    private

    def validate_role(project:, netid:, role:)
        if netid.blank?
            project.errors.add :base, "Missing netid for role #{role}"
        elsif User.where(uid: netid).empty?
            project.errors.add :base, "Invalid netid: #{netid} for role #{role}"
        end
    end

    def required_field_labels
        schema.required_project_schema_fields.pluck(:label)
    end

    def required_keys
        tableized = required_field_labels.map { |v| v.parameterize.underscore }
        tableized
    end

    def required_attributes(project:)
        project.metadata_json.select { |k, _v| required_keys.include?(k) }
    end

end
