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
    session_id = user.mediaflux_session
    id = project.save_in_mediaflux(session_id:)
    accum_count = Mediaflux::Http::CreateCollectionAccumulatorRequest.new(session_token: session_id, name: "accum-count", collection: id, type: "collection.asset.count")
    accum_count.resolve
    accum_size = Mediaflux::Http::CreateCollectionAccumulatorRequest.new(session_token: session_id, name: "accum-size", collection: id, type: "content.all.size")
    accum_size.resolve
    project.save!
    project
  end

  private

    def create_project
      metadata = {
        created_on: Time.current.in_time_zone("America/New_York").iso8601,
        created_by: user.uid,
        data_sponsor: sponsor.uid,
        data_manager: sponsor.uid,
        departments: departments,
        project_directory: "#{project_prefix}-#{sequence}",
        title: "Project #{project_prefix} #{sequence}",
        description: "Description of project #{project_prefix} #{sequence}",
        data_user_read_only: [],
        data_user_read_write: [],
        project_id: "doi-not-generated",
        storage_capacity: Rails.configuration.project_defaults[:storage_capacity],
        project_purpose: Rails.configuration.project_defaults[:project_purpose],
        storage_performance_expectations: Rails.configuration.project_defaults[:storage_performance_expectations],
        status: Project::PENDING_STATUS
      }
      project = Project.new(metadata: )
      project.save!
      project
    end

    def sponsor
      if (number % 7) == 0
        User.last
      elsif (number % 3) == 0
        User.all[2]
      else
        User.first
      end
    end

    def departments
      ldepartments = []
      ldepartments << Affiliation.all[3][:code] if (number % 7) == 0
      ldepartments << Affiliation.all[2][:code] if (number % 3) == 0
      ldepartments << Affiliation.all[1][:code] if (number % 5) == 0
      ldepartments << Affiliation.all[0][:code] if ldepartments.count == 0
      ldepartments
    end
end
