require "test_helper"

class Api::ProductsTest < ActionDispatch::IntegrationTest
  test "list items are slim: no description and no reviews" do
    create_product(name: "Saw", description: "A very long description " * 50)

    get "/api/products"

    item = response.parsed_body["products"].first
    assert_equal %w[category id name price_cents sku], item.keys.sort
    assert_equal "Saw", item["name"]
    assert_not_includes response.body, "very long description"
  end

  test "the catalog is paginated" do
    3.times { create_product }

    get "/api/products", params: { per_page: 2 }
    assert_equal 2, response.parsed_body["products"].size
    assert_equal({ "page" => 1, "per_page" => 2, "total" => 3 }, response.parsed_body["meta"])

    get "/api/products", params: { per_page: 2, page: 2 }
    assert_equal 1, response.parsed_body["products"].size
  end

  test "page size is capped" do
    get "/api/products", params: { per_page: 100_000 }

    assert_equal 100, response.parsed_body.dig("meta", "per_page")
  end
end
