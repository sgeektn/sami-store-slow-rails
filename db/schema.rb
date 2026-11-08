# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_01_000005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customers_on_email", unique: true
  end

  create_table "inventories", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.integer "quantity", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_inventories_on_product_id", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "name", null: false
    t.string "sku", null: false
    t.text "description", default: "", null: false
    t.integer "price_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["sku"], name: "index_products_on_sku", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "customer_id", null: false
    t.integer "rating", null: false
    t.text "body", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_reviews_on_customer_id"
    t.index ["product_id"], name: "index_reviews_on_product_id"
  end

  add_foreign_key "inventories", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "reviews", "customers"
  add_foreign_key "reviews", "products"
end
