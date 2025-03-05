# frozen_string_literal: true

namespace :file_inventory do
  desc "Attaches a file to a file inventory job"
  task :attach_file, [:job_id, :filename] => [:environment] do |_, args|
    job_id = args[:job_id]
    filename = args[:filename]

    request = FileInventoryRequest.where(job_id: job_id).first
    raise "Job #{job_id} not found" if request.nil?
    raise "File #{filename} not found" unless File.exist?(filename)

    puts "Attaching file #{filename} to job #{job_id}"
    request.completion_time = Time.current.in_time_zone("America/New_York")
    request.state = "completed"
    request.request_details = { file_size: File.size(filename), output_file: filename, project_title: request.project.title }
    request.save!
  end

  desc "Runs a file inventory job (asks for the MediaFlux credentials to use)"
  task :run, [:project_id, :netid] => [:environment] do |_, args|
    project_id = args[:project_id]
    netid = args[:netid]
    project = Project.find(project_id)
    user = User.where(uid: netid).first
    mediaflux_session = nil

    # Lets the user enter the credentials to use (domain, username, password)
    # notice that the password is not displayed
    puts "domain: "
    mf_domain = STDIN.gets.chomp

    puts "user: "
    mf_user = STDIN.gets.chomp

    puts "password: "
    mf_password = STDIN.getpass.chomp

    # Get a MediaFlux session for the credentials entered by the user
    logon_request = Mediaflux::LogonRequest.new(domain: mf_domain, user: mf_user, password: mf_password, identity_token: nil, token_type: nil)
    mediaflux_session = logon_request.session_token
    if logon_request.error?
      raise logon_request.response_error[:message]
    end

    # Schedule the file inventory job using the MediaFlux session we just adquired
    puts "Scheduling file inventory using credentials for: #{mf_domain}:#{mf_user}, session: #{mediaflux_session}"
    job_request = FileInventoryJob.perform_later(user_id: user.id, project_id: project.id, mediaflux_session: mediaflux_session)
    puts "Scheduled file inventory #{job_request.job_id} for project #{project.title} (#{project.id}) user: #{user.uid} (#{user.id}), session: #{mediaflux_session}"
  end
end
