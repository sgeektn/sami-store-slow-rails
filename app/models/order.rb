class Order < ApplicationRecord
  belongs_to :customer
  has_many :items, class_name: "OrderItem", dependent: :destroy

  validates :customer_email, presence: true
end
