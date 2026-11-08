class OrdersController < ApplicationController
  # BUG 2 (missing index): orders.customer_email has no index, so PostgreSQL scans the
  # whole orders table (300k rows) and sorts the matches on every call.
  # Fix lives on the fix/02-missing-index branch.
  def index
    email = params.require(:email)
    orders = Order.where(customer_email: email).order(placed_at: :desc).limit(50)

    render json: orders.as_json(only: %i[id status total_cents placed_at])
  end
end
