require "test_helper"

class CheckoutBackgroundJobTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @customer = create_customer
    @product = create_product
    ActionMailer::Base.deliveries.clear
  end

  test "checkout answers 202 with a pending order and does no slow work in the request" do
    post "/checkout", params: { email: @customer.email, product_id: @product.id, quantity: 1 }

    assert_response :accepted
    assert_equal "pending", response.parsed_body["status"]
    assert_equal "pending", Order.find(response.parsed_body["id"]).status
    assert_empty ActionMailer::Base.deliveries, "the email must not be sent inside the request"
    assert_enqueued_with(job: OrderProcessingJob)
  end

  test "the job charges the order, marks it paid and sends the confirmation" do
    order = create_order
    order.update!(status: "pending")

    perform_enqueued_jobs { OrderProcessingJob.perform_later(order.id) }

    assert_equal "paid", order.reload.status
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [order.customer_email], ActionMailer::Base.deliveries.last.to
  end
end
