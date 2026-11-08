# Simulates a call to a third party (payment provider, SMTP server) over the network
# and makes it show up as its own span in the trace.
module ExternalCall
  def self.simulate(name, latency:, attributes: {})
    tracer.in_span(name, attributes: attributes) { sleep(latency) }
  end

  def self.tracer
    OpenTelemetry.tracer_provider.tracer("sami_store")
  end
end
