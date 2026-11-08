ENV["RAILS_ENV"] ||= "test"
# No simulated network latency in tests.
ENV["PAYMENT_LATENCY"] ||= "0"
ENV["SMTP_LATENCY"] ||= "0"

require_relative "../config/environment"
require "rails/test_help"

module StoreTestHelpers
  def create_customer(email: "buyer@example.com")
    Customer.find_or_create_by!(email: email) { |c| c.name = "Buyer" }
  end

  def create_product(**attrs)
    category = attrs.delete(:category) || Category.first || Category.create!(name: "Tools")
    n = Product.count + 1
    product = Product.create!({ category: category, name: "Product #{n}", sku: "SKU-#{n}-#{SecureRandom.hex(3)}",
                                price_cents: 1000, description: "A product." }.merge(attrs))
    product.create_inventory!(quantity: 5)
    customer = create_customer
    [3, 5].each { |rating| product.reviews.create!(customer: customer, rating: rating, body: "ok") }
    product
  end

  def create_order(customer: create_customer, placed_at: Time.current)
    Order.create!(customer: customer, customer_email: customer.email, total_cents: 1000,
                  status: "paid", placed_at: placed_at)
  end

  # Number of SQL statements run by the block (schema lookups, transactions and cache hits excluded).
  def count_queries
    count = 0
    counter = lambda do |*, payload|
      count += 1 unless payload[:cached] || %w[SCHEMA TRANSACTION].include?(payload[:name])
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end
end

class ActiveSupport::TestCase
  include StoreTestHelpers
end
