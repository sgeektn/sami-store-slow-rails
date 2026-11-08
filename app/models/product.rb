class Product < ApplicationRecord
  belongs_to :category
  has_one :inventory, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :name, :sku, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  def review_count
    reviews.size
  end

  # Works on the loaded reviews. `reviews.average(:rating)` would run a new query every time.
  def average_rating
    return if reviews.empty?

    (reviews.sum(&:rating).to_f / reviews.size).round(1)
  end

  def stock
    inventory&.quantity.to_i
  end
end
