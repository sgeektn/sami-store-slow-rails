class ProductsController < ApplicationController
  PER_PAGE = 100

  # BUG 1 (N+1 queries): the view asks every product for its category, review stats and
  # stock level, and each of those is a separate query. 100 products = ~400 queries.
  # Fix lives on the fix/01-n-plus-one branch.
  def index
    @products = Product.order(:id).limit(PER_PAGE)
  end
end
