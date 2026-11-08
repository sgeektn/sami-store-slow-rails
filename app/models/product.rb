class Product < ApplicationRecord
  belongs_to :category
  has_one :inventory, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :name, :sku, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  def review_count
    reviews.size
  end

  def average_rating
    reviews.average(:rating)&.round(1)
  end

  def stock
    inventory&.quantity.to_i
  end
end
