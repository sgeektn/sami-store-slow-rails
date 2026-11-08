class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.string :sku, null: false
      t.text :description, null: false, default: ""
      t.integer :price_cents, null: false
      t.timestamps
    end
    add_index :products, :sku, unique: true
  end
end
