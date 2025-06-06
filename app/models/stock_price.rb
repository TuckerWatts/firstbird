class StockPrice < ApplicationRecord
  belongs_to :stock

  validates :date, presence: true
  validates :open, presence: true
  validates :high, presence: true
  validates :low, presence: true
  validates :close, presence: true
  validates :volume, presence: true
end 