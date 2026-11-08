require "test_helper"

# Smoke tests: every endpoint answers. They pass on main and on every fix branch.
class EndpointsTest < ActionDispatch::IntegrationTest
  test "GET /products lists products" do
    create_product(name: "Hammer")

    get "/products"

    assert_response :success
    assert_includes response.body, "Hammer"
  end

  test "GET /orders?email= returns the customer's orders" do
    order = create_order

    get "/orders", params: { email: "buyer@example.com" }

    assert_response :success
    assert_equal [order.id], response.parsed_body.map { |o| o["id"] }
  end

  test "GET /api/products returns products" do
    create_product(name: "Saw")

    get "/api/products"

    assert_response :success
    assert_includes response.body, "Saw"
  end

  test "POST /checkout creates an order" do
    customer = create_customer
    product = create_product

    assert_difference -> { customer.orders.count }, 1 do
      post "/checkout", params: { email: customer.email, product_id: product.id, quantity: 2 }
    end

    assert_response :success
    assert_equal 2000, customer.orders.last.total_cents
  end
end
