class StockAnalysis < ApplicationRecord
  belongs_to :stock

  validates :date, presence: true
  validates :sentiment_score, presence: true
  validates :technical_score, presence: true
  validates :overall_score, presence: true
end 