# Sends traces to an OTLP backend (SigNoz). Configured only through environment variables:
#
#   OTEL_EXPORTER_OTLP_ENDPOINT   e.g. http://localhost:4318 (self-hosted SigNoz)
#                                 or https://ingest.<region>.signoz.cloud:443 (SigNoz Cloud)
#   OTEL_EXPORTER_OTLP_HEADERS    e.g. signoz-ingestion-key=<key> (SigNoz Cloud only)
#   OTEL_SERVICE_NAME             defaults to "sami-store"
#   OTEL_SDK_DISABLED=true        turn tracing off entirely
#
# Without OTEL_EXPORTER_OTLP_ENDPOINT, tracing stays off and the app runs as usual.
return if Rails.env.test?
return if ENV["OTEL_SDK_DISABLED"] == "true"
return if ENV["OTEL_EXPORTER_OTLP_ENDPOINT"].to_s.empty?

require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"
require "opentelemetry/instrumentation/all"

OpenTelemetry::SDK.configure do |c|
  c.service_name = ENV.fetch("OTEL_SERVICE_NAME", "sami-store")
  c.use_all(
    # Keep traces readable: skip the noisy per-template and per-callback spans.
    "OpenTelemetry::Instrumentation::ActionView" => { enabled: false },
    "OpenTelemetry::Instrumentation::ActiveSupport" => { enabled: false }
  )
end
