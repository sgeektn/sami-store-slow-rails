# Stand-in for a third-party payment API. The latency is simulated, the span is real.
class PaymentProvider
  LATENCY = Float(ENV.fetch("PAYMENT_LATENCY", "0.6")) # seconds

  def self.charge!(order)
    ExternalCall.simulate("payment_provider.charge", latency: LATENCY,
                          attributes: { "order.id" => order.id, "order.total_cents" => order.total_cents })
  end
end
