class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :product, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :body, null: false, default: ""
      t.timestamps
    end
  end
end
