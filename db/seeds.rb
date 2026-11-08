# Seeds a hardware and workshop store big enough for the performance problems to be visible.
# Uses set-based SQL so it finishes in seconds, not minutes.
#
#   bin/rails db:seed
#   SEED_PRODUCTS=5000 SEED_ORDERS=20000 bin/rails db:seed   # smaller dataset
#
if Category.exists?
  puts "Database already seeded, skipping. (Run bin/rails db:reset to start over.)"
  return
end

products    = Integer(ENV.fetch("SEED_PRODUCTS", 50_000))
customers   = Integer(ENV.fetch("SEED_CUSTOMERS", 20_000))
reviews_max = Integer(ENV.fetch("SEED_MAX_REVIEWS_PER_PRODUCT", 10))
orders      = Integer(ENV.fetch("SEED_ORDERS", 1_000_000))
items_per   = Integer(ENV.fetch("SEED_ITEMS_PER_ORDER", 1))

# [category, item, variants, materials, price range in cents]. Expanded below into one
# concrete product per variant, so the catalog reads like a real one rather than
# "Product 1", "Product 2". Prices are per item and roughly what the real thing costs.
CATALOG = [
  ["Fasteners",        "Hex Bolt",            %w[M4 M6 M8 M10 M12],            ["Brass", "Stainless", "Galvanised", "Zinc-plated", "Hardened"], 30..260],
  ["Fasteners",        "Wood Screw",          ["3 x 20 mm", "4 x 30 mm", "5 x 50 mm", "5 x 80 mm"], ["Brass", "Stainless", "Zinc-plated", "Galvanised"], 240..900],
  ["Fasteners",        "Flat Washer",         %w[M4 M6 M8 M10],                ["Brass", "Stainless", "Nylon", "Rubber"], 15..120],
  ["Fasteners",        "Wing Nut",            %w[M5 M6 M8],                    ["Brass", "Stainless", "Zinc-plated"], 40..190],
  ["Fasteners",        "Coach Bolt",          ["M8 x 60", "M10 x 80", "M12 x 100"], ["Galvanised", "Stainless", "Zinc-plated"], 60..320],
  ["Fixings",          "Wall Plug",           ["5 mm", "6 mm", "8 mm", "10 mm"], ["Nylon", "Expanding", "Universal"], 190..620],
  ["Fixings",          "Angle Bracket",       ["40 mm", "60 mm", "90 mm"],     ["Galvanised", "Stainless", "Zinc-plated"], 150..720],
  ["Fixings",          "Joist Hanger",        ["47 x 100", "47 x 150"],        ["Galvanised", "Stainless"], 180..940],
  ["Door Hardware",    "Butt Hinge",          ["75 mm", "100 mm"],             ["Brass", "Stainless", "Chrome", "Black"], 250..1200],
  ["Door Hardware",    "Gate Latch",          %w[Standard Heavy],              ["Galvanised", "Black", "Stainless"], 600..2400],
  ["Door Hardware",    "Barrel Bolt",         ["100 mm", "150 mm"],            ["Brass", "Chrome", "Black"], 400..1500],
  ["Hand Tools",       "Claw Hammer",         ["16 oz", "20 oz"],              ["Forged", "Fibreglass", "Hickory"], 1200..3500],
  ["Hand Tools",       "Mallet",              %w[Round Square],                ["Rubber", "Beech", "Rawhide", "Nylon"], 900..2600],
  ["Hand Tools",       "Bevel Chisel",        ["6 mm", "12 mm", "25 mm"],      ["Carbon Steel", "Chrome Vanadium"], 800..2800],
  ["Hand Tools",       "Hand Plane",          ["No. 4", "No. 5"],              ["Cast Iron", "Ductile Iron"], 2500..9500],
  ["Hand Tools",       "Combination Pliers",  ["160 mm", "180 mm"],            ["Chrome Vanadium", "Forged", "Insulated"], 900..2600],
  ["Hand Tools",       "Adjustable Wrench",   ["200 mm", "250 mm", "300 mm"],  ["Chrome Vanadium", "Forged", "Chrome"], 1100..3200],
  ["Hand Tools",       "Hex Key Set",         %w[Metric Imperial],             ["Chrome Vanadium", "Ball-end", "Folding"], 700..2200],
  ["Hand Tools",       "Socket Set",          ["24 piece", "40 piece"],        ["Chrome Vanadium", "Impact", "Deep"], 2500..11_000],
  ["Cutting",          "Utility Knife",       %w[Retractable Fixed],           ["Aluminium", "Zinc Alloy", "Folding"], 500..1800],
  ["Cutting",          "Hacksaw",             ["300 mm", "Junior"],            ["Tubular", "Aluminium", "High-tension"], 700..2200],
  ["Cutting",          "Saw Blade",           ["165 mm", "190 mm", "216 mm"],  ["Tungsten Carbide", "Fine-tooth", "Ripping"], 1200..4500],
  ["Cutting",          "Tin Snips",           %w[Straight Left Right],         ["Forged", "Chrome Vanadium"], 1000..2800],
  ["Power Tools",      "Drill Bit Set",       %w[Wood Masonry Metal],          ["Titanium", "HSS", "Cobalt"], 1200..4800],
  ["Power Tools",      "Router Cutter",       ["6 mm", "8 mm", "12 mm"],       ["Tungsten Carbide", "Straight-flute"], 900..3600],
  ["Power Tools",      "Spade Bit",           ["16 mm", "20 mm", "25 mm"],     ["Flat", "Carbon Steel"], 400..1400],
  ["Abrasives",        "Sanding Block",       %w[Fine Medium Coarse],          ["Cork", "Rubber", "Foam"], 300..1200],
  ["Abrasives",        "Sanding Disc",        ["80 grit", "120 grit", "240 grit"], ["Aluminium Oxide", "Zirconia", "Ceramic"], 400..1500],
  ["Abrasives",        "Needle File",         %w[Flat Round Triangular],       ["Diamond", "Carbon Steel"], 500..1800],
  ["Measuring",        "Tape Measure",        ["5 m", "8 m", "10 m"],          ["Steel", "Nylon-coated", "Magnetic-tip"], 600..2400],
  ["Measuring",        "Spirit Level",        ["600 mm", "1200 mm"],           ["Aluminium", "Magnetic", "Box-section"], 900..3800],
  ["Measuring",        "Try Square",          ["150 mm", "250 mm"],            ["Rosewood", "Stainless", "Engineer's"], 700..2200],
  ["Measuring",        "Vernier Caliper",     ["150 mm", "200 mm"],            ["Stainless", "Digital", "Dial"], 1500..5500],
  ["Workshop Storage", "G-Clamp",             ["100 mm", "150 mm", "200 mm"],  ["Cast Iron", "Forged", "Quick-release"], 600..2400],
  ["Workshop Storage", "Tool Tray",           %w[Shallow Deep],                ["Steel", "Polypropylene"], 800..2600],
  ["Workshop Storage", "Parts Bin",           ["12 drawer", "24 drawer"],      ["Steel", "Modular"], 1500..4800],
  ["Paint and Finish", "Paint Brush",         ["25 mm", "50 mm", "75 mm"],     ["Synthetic", "Natural Bristle", "Angled"], 300..1400],
  ["Paint and Finish", "Roller Sleeve",       ["230 mm", "270 mm"],            ["Microfibre", "Sheepskin", "Foam"], 350..1200],
  ["Paint and Finish", "Danish Oil",          ["500 ml", "1 L"],               %w[Clear Natural Antique], 800..2600],
  ["Sealants",         "Caulking Gun",        %w[Skeleton Sausage],            ["Steel", "Heavy-duty"], 700..2400],
  ["Sealants",         "Silicone Sealant",    %w[Clear White Grey],            ["Sanitary", "Frame", "General-purpose"], 400..1100],
  ["Adhesives",        "Wood Glue",           ["250 ml", "1 L", "5 L"],        %w[PVA Waterproof Exterior], 350..1800],
  ["Adhesives",        "Epoxy Resin",         ["50 ml", "250 ml"],             %w[Rapid Clear Structural], 700..2600],
  ["Lubricants",       "Machine Oil",         ["100 ml", "500 ml"],            ["Light", "Multi-purpose"], 400..1200],
  ["Lubricants",       "Cutting Paste",       ["200 g", "500 g"],              ["Universal", "Heavy-duty"], 600..1800],
  ["Electrical",       "Cable Clip",          ["6 mm", "10 mm", "14 mm"],      %w[Nylon Steel Round], 200..700],
  ["Electrical",       "Junction Box",        ["2 way", "4 way"],              %w[Moulded Weatherproof], 300..1100],
  ["Plumbing",         "Compression Fitting", ["15 mm", "22 mm", "28 mm"],     %w[Brass Chrome], 150..800],
  ["Plumbing",         "Pipe Clip",           ["15 mm", "22 mm"],              %w[Brass Plastic Copper], 100..500],
  ["Safety Gear",      "Work Glove",          %w[Medium Large X-Large],        ["Leather", "Nitrile-coated", "Cut-resistant"], 400..1600],
  ["Safety Gear",      "Safety Goggle",       %w[Clear Tinted],                %w[Anti-fog Impact Vented], 400..1400],
  ["Safety Gear",      "Dust Mask",           %w[FFP2 FFP3],                   %w[Valved Moulded], 300..1200],
  ["Garden",           "Secateur",            %w[Bypass Anvil],                ["Forged", "Carbon Steel", "Titanium-coated"], 900..3200],
  ["Garden",           "Garden Line",         ["30 m", "50 m"],                %w[Braided Nylon], 400..1200],
  ["Timber",           "Dowel Rod",           ["6 mm", "10 mm", "16 mm"],      %w[Beech Oak Ramin], 150..600],
  ["Timber",           "Edging Strip",        ["18 mm", "22 mm"],              %w[Oak Beech Walnut], 250..900],
  ["Welding",          "Welding Rod",         ["2.5 mm", "3.2 mm"],            ["Mild Steel", "Stainless", "Low-hydrogen"], 600..2000],
  ["Ladders",          "Step Stool",          ["2 tread", "3 tread"],          %w[Aluminium Steel Folding], 2200..7500]
].freeze

# One row per concrete product: ["Brass Hex Bolt M4", "Fasteners", 30..260].
CATALOG_ROWS = CATALOG.flat_map do |category, item, variants, materials, price_range|
  variants.each_with_index.map do |variant, i|
    ["#{materials[i % materials.size]} #{item} #{variant}", category, price_range]
  end
end.freeze

conn = ActiveRecord::Base.connection
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

step = lambda do |label, sql|
  t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  conn.execute(sql)
  puts format("  %-12s %.1fs", label, Process.clock_gettime(Process::CLOCK_MONOTONIC) - t)
end

quote = ->(value) { conn.quote(value) }

# A stable pseudo-random integer from an expression. Anything linear in the row number
# (the obvious `id * 7919 % 180`) produces a visible arithmetic progression down the column,
# so stock levels and ratings are drawn from an md5 instead.
scatter = ->(expr) { "(('x' || substr(md5((#{expr})::text), 2, 7))::bit(28)::int)" }

# Walking the catalog with a coprime stride mixes the categories instead of listing
# all the fasteners first.
stride = (CATALOG_ROWS.size / 3).upto(CATALOG_ROWS.size).find { |n| n.gcd(CATALOG_ROWS.size) == 1 }

puts "Seeding Sami Store..."

step.call("categories", <<~SQL)
  INSERT INTO categories (name, created_at, updated_at)
  VALUES #{CATALOG.map(&:first).uniq.map { |c| "(#{quote.call(c)}, now(), now())" }.join(", ")}
SQL

catalog_values = CATALOG_ROWS.each_with_index.map do |(name, category, price_range), i|
  "(#{i}, #{quote.call(name)}, #{quote.call(category)}, #{price_range.first}, #{price_range.last})"
end.join(", ")

step.call("products", <<~SQL)
  INSERT INTO products (category_id, name, sku, description, price_cents, created_at, updated_at)
  SELECT c.id,
         cat.name,
         'SKU-' || lpad(g::text, 7, '0'),
         'Workshop grade, sold singly. Full dimensions, materials and torque ratings are on the datasheet. ' ||
           repeat('This line keeps the stored description realistically long. ', 16) || g,
         -- Scattered within the item's price range, then rounded so it ends in .49 or .99.
         ((cat.low + #{scatter.call('g')} % (cat.high - cat.low + 1)) / 50) * 50 + 49,
         now(), now()
  FROM generate_series(1, #{products}) g
  JOIN (VALUES #{catalog_values}) AS cat(idx, name, category_name, low, high)
    ON cat.idx = (g * #{stride}) % #{CATALOG_ROWS.size}
  JOIN categories c ON c.name = cat.category_name
SQL

step.call("inventories", <<~SQL)
  INSERT INTO inventories (product_id, quantity, created_at, updated_at)
  SELECT id, #{scatter.call("id * 3")} % 180, now(), now() FROM products
SQL

step.call("customers", <<~SQL)
  INSERT INTO customers (name, email, created_at, updated_at)
  SELECT 'Customer ' || g, 'customer' || g || '@example.com', now(), now()
  FROM generate_series(1, #{customers}) g
SQL

# Each product gets between 0 and SEED_MAX_REVIEWS_PER_PRODUCT reviews, so the review
# count is worth showing and some products have no rating at all.
step.call("reviews", <<~SQL)
  INSERT INTO reviews (product_id, customer_id, rating, body, created_at, updated_at)
  SELECT p.id,
         (SELECT min(id) FROM customers) + (p.id * r) % #{customers},
         -- Each product has its own quality level and its reviews scatter around it, so
         -- average ratings differ from product to product instead of all landing on 4.0.
         greatest(1, least(5, (2 + #{scatter.call('p.id * 7')} % 4)
                              - 1 + #{scatter.call('p.id * 11 + r')} % 3)),
         'Review ' || r || ' for product ' || p.id || '. Works as described.',
         now(), now()
  FROM products p
  CROSS JOIN LATERAL generate_series(1, #{scatter.call('p.id * 29')} % #{reviews_max + 1}) r
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
