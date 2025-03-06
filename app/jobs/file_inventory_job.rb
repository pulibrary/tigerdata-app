# frozen_string_literal: true
class FileInventoryJob < ApplicationJob
  # Create the FileInventoryRequest as soon as the job is created, not when it is performed
  before_enqueue do |job|
    project = Project.find(job.arguments.first[:project_id])
    FileInventoryRequest.create(user_id: job.arguments.first[:user_id], project_id: job.arguments.first[:project_id], job_id: @job_id, state: UserRequest::PENDING,
                                request_details: { project_title: project.title })
  end

  # This is required because the before_enqueue does not get called when perform_now is run on a job
  # We include both before_perform and before_enqueue so perform_now and perform_later will work as desired
  before_perform do |job|
    project = Project.find(job.arguments.first[:project_id])
    inventory_request = FileInventoryRequest.find_by(user_id: job.arguments.first[:user_id], project_id: job.arguments.first[:project_id], job_id: @job_id)
    if inventory_request.blank?
      FileInventoryRequest.create(user_id: job.arguments.first[:user_id], project_id: job.arguments.first[:project_id], job_id: @job_id, state: UserRequest::PENDING,
                                  request_details: { project_title: project.title })
    end
  end

  def perform(user_id:, project_id:, mediaflux_session:)
    project = Project.find(project_id)
    raise "Invalid project id #{project_id} for job #{job_id}" if project.nil?
    user = User.find(user_id)
    raise "Invalid user id #{user_id} for job #{job_id}" if user.nil?
    Rails.logger.debug inspect

    # set the mediaflux session to the one the user created, do not just utilize the system one
    user.mediaflux_from_session({ mediaflux_session: })

    # Queries Mediaflux for the file list and saves it to a CSV file.
    filename = filename_for_export
    Rails.logger.info "Exporting file list to #{filename} for project #{project_id} (session: #{mediaflux_session})"
    project.file_list_to_file(session_id: mediaflux_session, filename: filename)
    Rails.logger.info "Export file generated #{filename} for project #{project_id} (session: #{mediaflux_session})"

    # Update the job record as completed
    update_inventory_request(user_id: user.id, project: project, job_id: @job_id, filename: filename)
  end

  private

    def mediaflux_session
      logon_request = Mediaflux::LogonRequest.new
      logon_request.session_token
    end

    def filename_for_export
      raise "Shared location is not configured" if Rails.configuration.mediaflux["shared_files_location"].blank?
      pathname = Pathname.new(Rails.configuration.mediaflux["shared_files_location"])
      pathname.join("#{job_id}.csv").to_s
    end

    def update_inventory_request(user_id:, project:, job_id:, filename: )
      Rails.logger.info "Export - updating inventory request details for project #{project.id}"
      inventory_request = FileInventoryRequest.find_by(user_id: user_id, project_id: project.id, job_id: job_id)
      request_details = { output_file: filename, project_title: project.title, file_size: File.size(filename) }
      inventory_request.update(state: UserRequest::COMPLETED, request_details: request_details,
                                completion_time: Time.current.in_time_zone("America/New_York"))
      Rails.logger.info "Export - updated inventory request details for project #{project.id}"
      inventory_request
    rescue ActiveRecord::StatementInvalid
      Rails.logger.info "Export - updating inventory request details for project #{project.id} failed, about to retry"
      ActiveRecord::Base.connection_pool.release_connection
      retry
    end
end
