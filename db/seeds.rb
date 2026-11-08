# Seeds a store (1M orders by default) big enough for the performance problems to be visible.
# Uses set-based SQL so it finishes in seconds, not minutes.
#
#   bin/rails db:seed
#   SEED_PRODUCTS=5000 SEED_ORDERS=20000 bin/rails db:seed   # smaller dataset
#
if Category.exists?
  puts "Database already seeded, skipping. (Run bin/rails db:reset to start over.)"
  return
end

categories  = Integer(ENV.fetch("SEED_CATEGORIES", 20))
products    = Integer(ENV.fetch("SEED_PRODUCTS", 50_000))
customers   = Integer(ENV.fetch("SEED_CUSTOMERS", 20_000))
reviews_per = Integer(ENV.fetch("SEED_REVIEWS_PER_PRODUCT", 5))
orders      = Integer(ENV.fetch("SEED_ORDERS", 1_000_000))
items_per   = Integer(ENV.fetch("SEED_ITEMS_PER_ORDER", 1))

conn = ActiveRecord::Base.connection
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

step = lambda do |label, sql|
  t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  conn.execute(sql)
  puts format("  %-12s %.1fs", label, Process.clock_gettime(Process::CLOCK_MONOTONIC) - t)
end

puts "Seeding Sami Store..."

step.call("categories", <<~SQL)
  INSERT INTO categories (name, created_at, updated_at)
  SELECT 'Category ' || g, now(), now() FROM generate_series(1, #{categories}) g
SQL

step.call("products", <<~SQL)
  INSERT INTO products (category_id, name, sku, description, price_cents, created_at, updated_at)
  SELECT (SELECT min(id) FROM categories) + (g % #{categories}),
         'Product ' || g,
         'SKU-' || lpad(g::text, 7, '0'),
         repeat('Lorem ipsum dolor sit amet, consectetur adipiscing elit. ', 20) || g,
         500 + (g * 37) % 49500,
         now(), now()
  FROM generate_series(1, #{products}) g
SQL

step.call("inventories", <<~SQL)
  INSERT INTO inventories (product_id, quantity, created_at, updated_at)
  SELECT id, (id * 7) % 200, now(), now() FROM products
SQL

step.call("customers", <<~SQL)
  INSERT INTO customers (name, email, created_at, updated_at)
  SELECT 'Customer ' || g, 'customer' || g || '@example.com', now(), now()
  FROM generate_series(1, #{customers}) g
SQL

step.call("reviews", <<~SQL)
  INSERT INTO reviews (product_id, customer_id, rating, body, created_at, updated_at)
  SELECT p.id,
         (SELECT min(id) FROM customers) + (p.id * r) % #{customers},
         1 + (p.id + r) % 5,
         'Review ' || r || ' for product ' || p.id || '. Works as described.',
         now(), now()
  FROM products p CROSS JOIN generate_series(1, #{reviews_per}) r
SQL

# customer_email matches customers.email: customer k (1-based) has id min(id) + k - 1.
step.call("orders", <<~SQL)
  INSERT INTO orders (customer_id, customer_email, status, total_cents, placed_at, created_at, updated_at)
  SELECT (SELECT min(id) FROM customers) + (g % #{customers}),
         'customer' || ((g % #{customers}) + 1) || '@example.com',
         'paid',
         1000 + (g * 53) % 90000,
         now() - (g || ' minutes')::interval,
         now(), now()
  FROM generate_series(1, #{orders}) g
SQL

step.call("order_items", <<~SQL)
  INSERT INTO order_items (order_id, product_id, quantity, unit_price_cents, created_at, updated_at)
  SELECT o.id,
         (SELECT min(id) FROM products) + (o.id * r * 13) % #{products},
         1 + (o.id + r) % 3,
         500 + (o.id * r) % 49500,
         now(), now()
  FROM orders o CROSS JOIN generate_series(1, #{items_per}) r
SQL

conn.execute("ANALYZE")

total = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
puts format("Done in %.1fs: %d products, %d customers, %d reviews, %d orders.",
            total, Product.count, Customer.count, Review.count, Order.count)
