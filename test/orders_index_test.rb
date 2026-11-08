require "test_helper"

class OrdersIndexTest < ActiveSupport::TestCase
  test "orders can be looked up by customer email without scanning the table" do
    assert ActiveRecord::Base.connection.index_exists?(:orders, [:customer_email, :placed_at]),
           "expected an index on orders (customer_email, placed_at)"
  end
end
