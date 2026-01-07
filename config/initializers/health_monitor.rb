# frozen_string_literal: true

require "pul_cache"

Rails.application.config.after_initialize do
  HealthMonitor.configure do |config|

    config.file_absence.configure do |file_config|
      file_config.filename = "/opt/tigerdata/shared/remove-from-nginx"
    end
    # Mediaflux check
    config.add_custom_provider(MediafluxStatus)

    # allow the UI to load evn if mediaflux is down
    config.providers.last.configuration.critical = false

    # Make this health check available at /health
    config.path = :health

    # Use our custom Cache checker instead of the default one
    config.add_custom_provider(PULCache).configure

    config.error_callback = proc do |e|
      Rails.logger.error "Health check failed with: #{e.message}"
      unless e.is_a?(HealthMonitor::Providers::FileAbsenceException)
        Honeybadger.notify(e)
      end
    end
  end
end
