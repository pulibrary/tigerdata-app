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
    request = create_request
    project = request.approve(user)
    project.save!
    project
  end

  private

    def create_request
      # create a duplicate copy of the configuration so we do not modify the rails defaults
      capacity = Rails.configuration.project_defaults[:storage_capacity].deep_dup

      Request.create(metadata(capacity))
    end

    # rubocop:disable Metrics/MethodLength
    def metadata(capacity)
      {
        data_sponsor: "tigerdatatester", # Must be a valid netid/uid
        data_manager: "tigerdatatester", # Must be a valid netid/uid
        user_roles: [],
        quota: "custom",
        storage_size: capacity[:size][:requested],
        storage_unit: capacity[:unit][:requested],
        # For testing purposes we use the same size as the requested values
        approved_quota: "custom",
        approved_storage_size: capacity[:size][:requested],
        approved_storage_unit: capacity[:unit][:requested],
        project_title: "Project #{project_prefix} #{sequence}",
        departments: departments,
        description: "Description of project #{project_prefix} #{sequence}",
        project_folder: "#{project_prefix}-#{sequence}",
        project_purpose: Rails.configuration.project_defaults[:project_purpose]
        # storage_performance_expectations: Rails.configuration.project_defaults[:storage_performance_expectations]
      }
    end
    # rubocop:enable Metrics/MethodLength

    def departments
      ldepartments = []
      ldepartments << Affiliation.all[3] if (number % 7) == 0
      ldepartments << Affiliation.all[2] if (number % 3) == 0
      ldepartments << Affiliation.all[1] if (number % 5) == 0
      ldepartments << Affiliation.all[0] if ldepartments.count == 0
      ldepartments
    end
end
