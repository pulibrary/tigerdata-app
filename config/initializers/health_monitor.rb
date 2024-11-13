# frozen_string_literal: true
Rails.application.config.after_initialize do
  HealthMonitor.configure do |config|
    config.cache

    config.file_absence.configure do |file_config|
      file_config.filename = "public/remove-from-nginx"
    end
    # Mediaflux check
    config.add_custom_provider(MediafluxStatus)

    # Make this health check available at /health
    config.path = :health

    config.error_callback = proc do |e|
      unless e.is_a?(HealthMonitor::Providers::FileAbsenceException)
        Rails.logger.error "Health check failed with: #{e.message}"
        Honeybadger.notify(e)
      end
    end
  end
end
