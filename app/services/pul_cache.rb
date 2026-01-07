# frozen_string_literal: true

require "health_monitor/providers/cache"

class PULCacheException < StandardError; end

class PULCache < HealthMonitor::Providers::Cache
  def check!
    time = Time.now.utc.to_fs(:rfc2822)

    Rails.cache.write(key, time)
    fetched = Rails.cache.read(key)

    # NOTE: we might want to add logic to allow a small difference
    # here, but we let's not do this until we see if the issue persists
    # with this new implementation that calculates a better key.
    raise "different values (now: #{time}, fetched: #{fetched})" if fetched != time
  rescue RuntimeError => e
    raise PulCacheException, e.message
    end

    private

    def key
      random = rand(99_999)
      @key ||= ["health", request.try(:remote_ip), random].join(":")
    end
end