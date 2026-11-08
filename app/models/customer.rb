class Customer < ApplicationRecord
  has_many :reviews, dependent: :destroy
  has_many :orders, dependent: :restrict_with_exception

  validates :name, :email, presence: true
end
