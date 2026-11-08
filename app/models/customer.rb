class Customer < ApplicationRecord
  has_many :reviews, dependent: :destroy

  validates :name, :email, presence: true
end
