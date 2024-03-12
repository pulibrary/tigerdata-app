# frozen_string_literal: true

require "ddtrace"
require "datadog/statsd"
require "datadog/profiling/preload"

Datadog.configure do |c|
  c.env = Rails.env
  c.service = "tigerdata"
  c.version = "1.0.0"
  c.profiling.enabled = Rails.env.staging? || Rails.env.production?

  c.tracing.report_hostname = Rails.env.staging? || Rails.env.production?
  c.tracing.analytics.enabled = Rails.env.staging? || Rails.env.production?
  c.tracing.enabled = Rails.env.staging? || Rails.env.production?
  c.tracing.report_hostname = Rails.env.staging? || Rails.env.production?
  c.tracing.log_injection = Rails.env.staging? || Rails.env.production?

  # From https://docs.datadoghq.com/tracing/metrics/runtime_metrics/ruby/
  # To enable runtime metrics collection, set `true`. Defaults to `false`
  # You can also set DD_RUNTIME_METRICS_ENABLED=true to configure this.
  c.runtime_metrics.enabled = Rails.env.staging? || Rails.env.production?

  # Optionally, you can configure the DogStatsD instance used for sending runtime metrics.
  # DogStatsD is automatically configured with default settings if `dogstatsd-ruby` is available.
  # You can configure with host and port of Datadog agent; defaults to 'localhost:8125'.
  c.runtime_metrics.statsd = Datadog::Statsd.new

  # Rails
  c.tracing.instrument :rails

  # Net::HTTP
  c.tracing.instrument :http
end
