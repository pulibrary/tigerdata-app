class ProjectValidator < ActiveModel::Validator
    def validate(project)
        # Required fields, always validate
        validate_role(project:, netid: project.metadata[:data_manager], role: "Data Manager")
        validate_role(project:, netid: project.metadata[:data_sponsor], role: "Data Sponsor")

        # Validate if present
        project.metadata[:data_user_read_only]&.each { |read_only| validate_role(project:, netid: read_only, role: "Data User Read Only")}
        project.metadata[:data_user_read_write]&.each { |read_write| validate_role(project:, netid: read_write, role: "Data User Read Write")}
    end

    private

    def validate_role(project:, netid:, role:)
        if netid.blank?
            project.errors.add :base, "Mising netid for role #{role}"
        elsif User.where(uid: netid).empty?
            project.errors.add :base, "Invalid netid: #{netid} for role #{role}"
        end
    end
end