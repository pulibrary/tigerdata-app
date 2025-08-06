# frozen_string_literal: true
class RequestCleanupJob < ApplicationJob
  queue_as :default

  def perform
    # Destroy every request in the database that is not valid to submit and has 6 or more errors
    Request.where.not(state: Request::SUBMITTED).each do |request|
      # check if the request has not been updated within 24 hours
      next unless request.updated_at < 24.hours.ago
      request.valid_to_submit?
      # 6 errors is arbitrary, but it is the number of manditory fields (excluding pre-populated fields) in the request form
      if request.errors.count >= 6
        request.destroy
      end
    end
  end
end
