class ProductsController < ApplicationController
  PER_PAGE = 100

  # Fix for bug 1: load the category, inventory and reviews for the whole page up front
  # (one extra query per association) instead of once per product.
  def index
    @products = Product.includes(:category, :inventory, :reviews).order(:id).limit(PER_PAGE)
  end
end
