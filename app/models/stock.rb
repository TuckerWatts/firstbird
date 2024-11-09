class Stock < ApplicationRecord
  has_many :historical_prices, dependent: :destroy
  has_many :predictions, dependent: :destroy

  validates :symbol, presence: true
end
