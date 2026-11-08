class CheckoutController < ApplicationController
  skip_forgery_protection # JSON API used by the benchmarks

  # Fix for bug 4: record the order as pending, answer right away (202 Accepted) and let
  # OrderProcessingJob charge the card and send the email in the background.
  #
  # Demo simplification: a real shop would usually authorize the payment before accepting
  # the order, and only move the capture and the email to a job.
  def create
    customer = Customer.find_by!(email: params.require(:email))
    product = Product.find(params.require(:product_id))
    quantity = params.fetch(:quantity, 1).to_i

    order = Order.transaction do
      Order.create!(customer: customer, customer_email: customer.email, placed_at: Time.current,
                    total_cents: product.price_cents * quantity).tap do |o|
        o.items.create!(product: product, quantity: quantity, unit_price_cents: product.price_cents)
      end
    end

    OrderProcessingJob.perform_later(order.id)

    render json: { id: order.id, status: order.status }, status: :accepted
  end
end
