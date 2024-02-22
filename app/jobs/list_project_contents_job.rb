# frozen_string_literal: true
class ListProjectContentsJob < ApplicationJob
  # Asynchronously query Mediaflux for Project assets and cache the results for rendering to the end-user
  def perform(user_id:, project_title:)
    # @todo Query for all contents within any given project

    @user_id = user_id
    raise(ArgumentError, "Failed to retrieve the User for the ID #{@user_id}") if user.nil?

    @project_title = project_title

    user.user_jobs << user_job
    user.save!
  end

  private

    def user
      @user ||= User.find_by(id: @user_id)
    end

    def user_job
      @user_job ||= begin
                      user_job = UserJob.create(job_id:, project_title: @project_title)
                      user_job.completed_at = DateTime.now
                      user_job.save!
                      user_job.reload
                    end
    end
end
