# frozen_string_literal: true
class FileInventoryCleanupJob < ApplicationJob
  queue_as :default

  def perform
    FileInventoryRequest.where(["completion_time < ?", 7.days.ago]).each do |req|
      File.delete(req.output_file) if File.exist?(req.output_file)
      req.state = UserRequest::STALE
      req.save
    end
  end
end
