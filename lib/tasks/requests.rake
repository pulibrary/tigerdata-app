# frozen_string_literal: true
namespace :request do
  desc "Runs RequestCleanupJob to clean up old requests"
  task clean_up: :environment do
    RequestCleanupJob.perform_later
  end
end
