class OrderMailer < ApplicationMailer
  SMTP_LATENCY = Float(ENV.fetch("SMTP_LATENCY", "0.4")) # seconds

  def confirmation(order)
    @order = order
    # Stand-in for the round trip to a real SMTP / email API.
    ExternalCall.simulate("smtp.deliver", latency: SMTP_LATENCY, attributes: { "order.id" => order.id })

    mail(to: order.customer_email, subject: "Your Sami Store order ##{order.id}")
  end
end
