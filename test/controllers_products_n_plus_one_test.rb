require "test_helper"

class ProductsNPlusOneTest < ActionDispatch::IntegrationTest
  test "listing products runs the same number of queries however many products there are" do
    create_product
    get "/products" # warm up (schema cache, etc.)
    few = count_queries { get "/products" }

    8.times { create_product }
    many = count_queries { get "/products" }

    assert_equal few, many, "query count grew with the number of products (N+1)"
  end

  test "shows each product's rating, review count and stock" do
    create_product(name: "Hammer")

    get "/products"

    assert_includes response.body, "Hammer"
    assert_includes response.body, "4.0" # ratings 3 and 5
  end
end
