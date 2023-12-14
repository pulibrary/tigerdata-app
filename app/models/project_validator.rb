class ProjectValidator < ActiveModel::Validator
    def validate(project)
        validate_role(project:, netid: project.metadata[:data_manager], role: "Data Manager")
        validate_role(project:, netid: project.metadata[:data_sponsor], role: "Data Sponsor")
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