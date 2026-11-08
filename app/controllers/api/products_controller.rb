module Api
  class ProductsController < ApplicationController
    LIMIT = 1000

    # BUG 3 (heavy serialization): the associations are eager loaded (no N+1 here), but the
    # response carries every column of every product, its full description, its category
    # and all of its reviews, with no way to page through the catalog. The database is
    # fast; Ruby spends its time building and encoding a multi-megabyte JSON document.
    # Fix lives on the fix/03-serialization branch.
    def index
      products = Product.includes(:category, :reviews).order(:id).limit(LIMIT)

      render json: products.as_json(include: %i[category reviews])
    end
  end
end
