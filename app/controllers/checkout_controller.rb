class CheckoutController < ApplicationController
  skip_forgery_protection # JSON API used by the benchmarks

  # BUG 4 (slow work inside the request): the response is held back by the payment
  # provider call and the confirmation email, about a second of pure waiting that the
  # customer sits through. Fix lives on the fix/04-background-job branch.
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

    PaymentProvider.charge!(order)
    order.update!(status: "paid")
    OrderMailer.confirmation(order).deliver_now

    render json: { id: order.id, status: order.status }, status: :created
  end
end
