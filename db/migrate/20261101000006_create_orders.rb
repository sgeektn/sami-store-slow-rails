class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      # Denormalised copy of the customer's email, used by the "find my orders" lookup.
      t.string :customer_email, null: false
      t.string :status, null: false, default: "pending"
      t.integer :total_cents, null: false, default: 0
      t.datetime :placed_at, null: false
      t.timestamps
    end
  end
end
