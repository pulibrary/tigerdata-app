# frozen_string_literal: true
class TestProjectGenerator
  attr_reader :user, :number, :sequence, :project_prefix

  def initialize(user:, number:, project_prefix:)
    @user = user
    @number = number
    @sequence = number.to_s.rjust(5, "0")
    @project_prefix = project_prefix
  end

  def generate
    project = create_project
    project.approve!(current_user: user)
    project.save!
    project
  end

  private

    def create_project
      # create a duplicate copy of the configuration so we do not modify the rails defaults
      capacity = Rails.configuration.project_defaults[:storage_capacity].deep_dup
      # For testing purposes we use the same size as the requested values
      capacity[:size][:approved] = capacity[:size][:requested]
      capacity[:unit][:approved] = capacity[:unit][:requested]

      metadata = {
        created_on: Time.current.in_time_zone("America/New_York").iso8601,
        created_by: user.uid,
        data_sponsor: sponsor.uid,
        data_manager: sponsor.uid,
        data_user_read_only: [],
        data_user_read_write: [user.uid],
        departments: departments,
        project_directory: "#{project_prefix}-#{sequence}",
        title: "Project #{project_prefix} #{sequence}",
        description: "Description of project #{project_prefix} #{sequence}",
        project_id: project_id,
        storage_capacity: capacity,
        project_purpose: Rails.configuration.project_defaults[:project_purpose],
        storage_performance_expectations: Rails.configuration.project_defaults[:storage_performance_expectations],
        status: Project::PENDING_STATUS
      }
      project = Project.new(metadata: )
      project.save!
      project
    end

    def sponsor
      return User.where(uid: "hc8719").first
    end

    def departments
      ldepartments = []
      ldepartments << Affiliation.all[3][:code] if (number % 7) == 0
      ldepartments << Affiliation.all[2][:code] if (number % 3) == 0
      ldepartments << Affiliation.all[1][:code] if (number % 5) == 0
      ldepartments << Affiliation.all[0][:code] if ldepartments.count == 0
      ldepartments
    end

    def project_id
      part1 = rand(1...99).to_s.rjust(2, "0")
      part2 = rand(1...99999).to_s.rjust(5, "0")
      part3 = rand(1...9999).to_s.rjust(4, "0")
      part4 = rand(1...9999).to_s.rjust(4, "0")
      "#{part1}.#{part2}/#{part3}-#{part4}"
    end
end
