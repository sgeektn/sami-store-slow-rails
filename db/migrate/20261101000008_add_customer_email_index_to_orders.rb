class AddCustomerEmailIndexToOrders < ActiveRecord::Migration[8.1]
  # CREATE INDEX CONCURRENTLY cannot run inside a transaction. It avoids locking writes
  # on a busy orders table while the index is built.
  disable_ddl_transaction!

  def change
    # The lookup is WHERE customer_email = ? ORDER BY placed_at DESC LIMIT 50. With this index
    # PostgreSQL finds the customer's rows through the index instead of scanning every order.
    add_index :orders, [:customer_email, :placed_at],
              order: { placed_at: :desc },
              algorithm: :concurrently,
              name: "index_orders_on_customer_email_and_placed_at"
  end
end
