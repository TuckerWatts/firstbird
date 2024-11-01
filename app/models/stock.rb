class Stock < ApplicationRecord
  has_many :historical_prices
  has_many :predictions, dependent: :destroy

  validates :symbol, presence: true
end
