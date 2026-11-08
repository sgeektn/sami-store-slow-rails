class Review < ApplicationRecord
  belongs_to :product
  belongs_to :customer

  validates :rating, inclusion: { in: 1..5 }
end
