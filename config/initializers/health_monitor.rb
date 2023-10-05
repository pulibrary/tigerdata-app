# frozen_string_literal: true
HealthMonitor.configure do |config|
  config.cache

  # Make this health check available at /health
  config.path = :health

  config.error_callback = proc do |e|
    Rails.logger.error "Health check failed with: #{e.message}"
    Honeybadger.notify(e)
  end
end
