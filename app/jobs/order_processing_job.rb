# Charges the order and sends the confirmation email, outside the web request.
class OrderProcessingJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find(order_id)

    PaymentProvider.charge!(order)
    order.update!(status: "paid")
    OrderMailer.confirmation(order).deliver_now
  end
end
