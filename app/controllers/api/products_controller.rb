module Api
  class ProductsController < ApplicationController
    DEFAULT_PER_PAGE = 50
    MAX_PER_PAGE = 100

    # Fix for bug 3: page through the catalog and send only what a list needs.
    #   GET /api/products?page=2&per_page=50
    def index
      page = [params.fetch(:page, 1).to_i, 1].max
      per_page = params.fetch(:per_page, DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)

      products = Product.includes(:category)
                        .select(:id, :name, :sku, :price_cents, :category_id)
                        .order(:id)
                        .limit(per_page)
                        .offset((page - 1) * per_page)

      render json: {
        products: products.map { |p| serialize(p) },
        meta: { page: page, per_page: per_page, total: Product.count }
      }
    end

    private

    def serialize(product)
      { id: product.id, name: product.name, sku: product.sku,
        price_cents: product.price_cents, category: product.category.name }
    end
  end
end
