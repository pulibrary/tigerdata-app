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
    request.request_details = { file_size: File.size(filename), output_file: filename }
    request.save!
  end
end
